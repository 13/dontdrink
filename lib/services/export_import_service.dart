import 'dart:convert';
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
  const ImportSuccess(this.count);
  final int count;
}

class ImportCancelled extends ImportResult {
  const ImportCancelled();
}

class ImportError extends ImportResult {
  const ImportError(this.message);
  final String message;
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

  Future<void> export({
    required List<ModeDefinition> modes,
    required Map<String, List<DayEntry>> entriesByMode,
  }) async {
    final payload = buildPayload(modes: modes, entriesByMode: entriesByMode);

    final json = const JsonEncoder.withIndent('  ').convert(payload);
    final dir = await getTemporaryDirectory();
    final filename =
        "dont_drink_backup_${DateOnly.keyFor(DateTime.now())}.json";
    final file = File('${dir.path}/$filename');
    await file.writeAsString(json, encoding: utf8);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: "Don't Drink — data backup",
    );
  }

  // ── Import ───────────────────────────────────────────────────────────────

  /// Apply a decoded backup payload. Pure of file pickers for the same reason
  /// as [buildPayload].
  ///
  /// Accepts both version 1 (single-mode, no `mode_id`) and version 2. Custom
  /// modes named in the backup are recreated (keeping their original id)
  /// before entries are applied, so those entries resolve. Entries naming a
  /// mode that cannot be resolved are skipped rather than failing the whole
  /// import.
  Future<ImportResult> applyPayload(
    Map<String, dynamic> payload, {
    required EntryRepository entries,
    required ModeRepository modes,
  }) async {
    if (payload['app'] != 'dont_drink') {
      return const ImportError(
          "This file doesn't look like a Don't Drink backup.");
    }

    final rawEntries = payload['entries'];
    if (rawEntries is! List) {
      return const ImportError('Backup file is missing the entries list.');
    }

    // Recreate any custom modes the backup carried, so their entries resolve.
    final rawModes = payload['custom_modes'];
    if (rawModes is List) {
      final existing = {for (final m in await modes.customModes()) m.id};
      for (final raw in rawModes) {
        if (raw is! Map) continue;
        final id = raw['id'] as String?;
        final name = raw['name'] as String?;
        if (id == null || name == null || existing.contains(id)) continue;
        await modes.restoreCustom(
          id: id,
          name: name,
          emoji: raw['emoji'] as String? ?? '🎯',
        );
      }
    }

    // Index every known mode by id so a level integer can be resolved.
    final byId = {for (final mode in await modes.allModes()) mode.id: mode};

    int count = 0;
    try {
      for (final raw in rawEntries) {
        if (raw is! Map) continue;
        final map = Map<String, Object?>.from(raw);
        final modeId = map['mode_id'] as String? ?? kDefaultMode.id;
        final mode = byId[modeId];
        if (mode == null) continue; // unknown mode — skip, don't fail
        await entries.upsert(DayEntry.fromMap(map, mode));
        count++;
      }
    } catch (e) {
      return ImportError('Import failed after $count entries: $e');
    }

    return ImportSuccess(count);
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
        return const ImportError('Could not read the selected file.');
      }
    } catch (e) {
      return ImportError('Failed to read file: $e');
    }

    // Parse JSON.
    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return const ImportError('The selected file is not valid JSON.');
    }

    return applyPayload(payload, entries: entries, modes: modes);
  }
}
