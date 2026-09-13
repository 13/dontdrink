import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:dont_drink/core/models/day_entry.dart';
import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/core/utils/date_utils.dart';
import 'package:dont_drink/data/repositories/entry_repository.dart';
import 'package:dont_drink/data/repositories/mode_repository.dart';
import 'package:dont_drink/data/static/modes/mode_registry.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// The result of an import attempt.
sealed class ImportResult {
  const ImportResult();
}

class ImportSuccess extends ImportResult {
  const ImportSuccess(this.count, {this.skipped = 0});

  /// Entries actually written.
  final int count;

  /// Entries present in the file that could not be applied — an unknown
  /// mode, a malformed row, or (v2 only) a missing `mode_id`. Not fatal, but
  /// worth surfacing so a partial import isn't mistaken for a complete one.
  final int skipped;
}

class ImportCancelled extends ImportResult {
  const ImportCancelled();
}

/// Why an import failed. The wording lives in the .arb files: this service
/// runs outside the widget tree and must not decide what language the user
/// reads.
enum ImportFailure {
  /// The file is JSON, but not one of ours.
  notABackup,

  /// Our file, but the entries list is absent or the wrong type.
  missingEntries,

  /// Some entries were written before something threw — a partial import.
  partial,

  /// The picker returned a file with neither bytes nor a readable path.
  unreadable,

  /// Reading the bytes threw.
  readFailed,

  /// The content is not valid JSON at all.
  invalidJson,
}

class ImportError extends ImportResult {
  const ImportError(this.failure, {this.detail, this.count = 0});

  final ImportFailure failure;

  /// Exception text for the failures that carry one, else null.
  final String? detail;

  /// Entries already applied when a [ImportFailure.partial] failure hit.
  final int count;
}

/// What an export attempt did.
sealed class ExportResult {
  const ExportResult();
}

/// Written to [path], which is wherever the user pointed the file picker.
class ExportSaved extends ExportResult {
  const ExportSaved(this.path);
  final String path;
}

/// The user backed out of the picker. Not an error, and not worth a message.
class ExportCancelled extends ExportResult {
  const ExportCancelled();
}

class ExportFailed extends ExportResult {
  const ExportFailed(this.detail);
  final String detail;
}

/// Writes [bytes] wherever the user chooses, returning the path or null if
/// they cancelled.
///
/// Injected so the export can be tested without a platform file picker, which
/// has no host implementation.
typedef BackupSaver = Future<String?> Function({
  required String fileName,
  required Uint8List bytes,
});

Future<String?> _saveWithPicker({
  required String fileName,
  required Uint8List bytes,
}) {
  return FilePicker.platform.saveFile(
    fileName: fileName,
    bytes: bytes,
    type: FileType.custom,
    allowedExtensions: const ['json'],
  );
}

/// Handles JSON export and import of all [DayEntry] data, across every
/// tracking mode.
///
/// Export: serialises entries → writes a temp JSON file → opens the OS share
/// sheet so the user can save or send it anywhere (Files, email, etc.).
///
/// Import: opens the OS file picker → reads and validates the JSON → upserts
/// every entry into the database (existing days are overwritten, new days are
/// added, days not in the file are left untouched).
///
/// The payload format is versioned:
/// - Version 1 (legacy, single-mode): entries have no `mode_id` and always
///   resolve to [kDefaultMode] (`dont_drink`) — that is what those entries
///   always were.
/// - Version 2 (multi-mode): entries carry `mode_id`, and `custom_modes`
///   carries any non-built-in mode definitions needed to resolve them.
class ExportImportService {
  const ExportImportService();

  // ── Export ───────────────────────────────────────────────────────────────

  /// Build the backup payload. Pure — no file or share-sheet involvement — so
  /// the format can be tested directly.
  Map<String, Object?> buildPayload({
    required List<ModeDefinition> modes,
    required Map<String, List<DayEntry>> entriesByMode,
  }) {
    final rows = [
      for (final list in entriesByMode.values)
        for (final entry in list) entry.toMap(),
    ];
    return {
      'version': 2,
      'app': 'dont_drink',
      'exported_at': DateOnly.keyFor(DateTime.now()),
      'entry_count': rows.length,
      'custom_modes': [
        for (final mode in modes)
          if (!mode.isBuiltIn)
            {'id': mode.id, 'name': mode.name, 'emoji': mode.emoji},
      ],
      'entries': rows,
    };
  }

  /// Write a backup to a location the user picks.
  ///
  /// Sharing a file only ever offered whatever apps accept a JSON intent,
  /// which on many phones does not include a file manager — so "export" could
  /// not actually put a backup on the device. This goes through the system's
  /// save dialog instead, which is the thing that can.
  Future<ExportResult> saveBackup({
    required List<ModeDefinition> modes,
    required Map<String, List<DayEntry>> entriesByMode,
    BackupSaver saver = _saveWithPicker,
  }) async {
    final payload = buildPayload(modes: modes, entriesByMode: entriesByMode);
    final json = const JsonEncoder.withIndent('  ').convert(payload);

    try {
      final path = await saver(
        fileName: backupFileName(),
        bytes: Uint8List.fromList(utf8.encode(json)),
      );
      if (path == null) return const ExportCancelled();
      return ExportSaved(path);
    } catch (e) {
      return ExportFailed('$e');
    }
  }

  /// The name a backup is offered under, dated so several can sit side by side.
  String backupFileName() =>
      'dont_drink_backup_${DateOnly.keyFor(DateTime.now())}.json';

  Future<void> export({
    required List<ModeDefinition> modes,
    required Map<String, List<DayEntry>> entriesByMode,
    required String shareSubject,
  }) async {
    final payload = buildPayload(modes: modes, entriesByMode: entriesByMode);

    final json = const JsonEncoder.withIndent('  ').convert(payload);
    final dir = await getTemporaryDirectory();
    final filename = backupFileName();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(json, encoding: utf8);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: shareSubject,
    );
  }

  // ── Import ───────────────────────────────────────────────────────────────

  /// Apply a decoded backup payload. Pure of file pickers for the same reason
  /// as [buildPayload].
  ///
  /// Accepts both version 1 (single-mode, no `mode_id`) and version 2. Custom
  /// modes named in the backup are recreated (keeping their original id)
  /// before entries are applied, so those entries resolve. A version 1 entry
  /// with no `mode_id` resolves to [kDefaultMode] — that is what those
  /// entries always were. A version 2 entry with no `mode_id` is skipped
  /// rather than guessed at, since a level integer only means something
  /// within its own mode. Any row — an entry or a custom-mode definition —
  /// that cannot be resolved or is malformed (e.g. hand-edited or truncated
  /// file content with the wrong type) is skipped rather than failing the
  /// whole import.
  Future<ImportResult> applyPayload(
    Map<String, dynamic> payload, {
    required EntryRepository entries,
    required ModeRepository modes,
  }) async {
    if (payload['app'] != 'dont_drink') {
      return const ImportError(ImportFailure.notABackup);
    }

    final rawEntries = payload['entries'];
    if (rawEntries is! List) {
      return const ImportError(ImportFailure.missingEntries);
    }

    final version = payload['version'];
    final isV1 = version == null || version == 1;

    int count = 0;
    int skipped = 0;
    try {
      // Recreate any custom modes the backup carried, so their entries
      // resolve. Everything here reads untrusted file content, so every
      // field is type-tested rather than cast — a malformed mode definition
      // is skipped, not fatal.
      final rawModes = payload['custom_modes'];
      if (rawModes is List) {
        final existing = {for (final m in await modes.customModes()) m.id};
        for (final raw in rawModes) {
          if (raw is! Map) continue;
          final id = raw['id'];
          final name = raw['name'];
          if (id is! String || name is! String || existing.contains(id)) {
            continue;
          }
          final rawEmoji = raw['emoji'];
          await modes.restoreCustom(
            id: id,
            name: name,
            emoji: rawEmoji is String ? rawEmoji : '🎯',
          );
        }
      }

      // Index every known mode by id so a level integer can be resolved.
      final byId = {
        for (final mode in await modes.allModes()) mode.id: mode,
      };

      for (final raw in rawEntries) {
        if (raw is! Map) {
          skipped++;
          continue;
        }
        final map = Map<String, Object?>.from(raw);
        final rawModeId = map['mode_id'];
        final modeId = rawModeId is String
            ? rawModeId
            : (isV1 ? kDefaultMode.id : null);
        if (modeId == null) {
          skipped++;
          continue; // v2 row with no mode_id — skip, don't guess
        }
        final mode = byId[modeId];
        if (mode == null) {
          skipped++;
          continue; // unknown mode — skip, don't fail
        }
        try {
          await entries.upsert(DayEntry.fromMap(map, mode));
          count++;
        } catch (_) {
          // A malformed row (wrong type for date_key/level/updated_at) —
          // skip it and keep processing the rest of the file, same as every
          // other kind of bad row above.
          skipped++;
        }
      }
    } catch (e) {
      return ImportError(ImportFailure.partial, detail: '$e', count: count);
    }

    return ImportSuccess(count, skipped: skipped);
  }

  /// Prompts the user to pick a backup file and applies it via
  /// [applyPayload]. Returns an [ImportResult] describing what happened.
  Future<ImportResult> import({
    required EntryRepository entries,
    required ModeRepository modes,
  }) async {
    // Pick file.
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return const ImportCancelled();
    }

    // Read content.
    final picked = result.files.first;
    String content;
    try {
      if (picked.bytes != null) {
        content = utf8.decode(picked.bytes!);
      } else if (picked.path != null) {
        content = await File(picked.path!).readAsString(encoding: utf8);
      } else {
        return const ImportError(ImportFailure.unreadable);
      }
    } catch (e) {
      return ImportError(ImportFailure.readFailed, detail: '$e');
    }

    // Parse JSON.
    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return const ImportError(ImportFailure.invalidJson);
    }

    return applyPayload(payload, entries: entries, modes: modes);
  }
}
