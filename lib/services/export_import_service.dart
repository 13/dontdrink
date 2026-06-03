import 'dart:convert';
import 'dart:io';

import 'package:dont_drink/core/models/day_entry.dart';
import 'package:dont_drink/core/utils/date_utils.dart';
import 'package:dont_drink/data/repositories/entry_repository.dart';
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

/// Handles JSON export and import of all [DayEntry] data.
///
/// Export: serialises entries → writes a temp JSON file → opens the OS share
/// sheet so the user can save or send it anywhere (Files, email, etc.).
///
/// Import: opens the OS file picker → reads and validates the JSON → upserts
/// every entry into the database (existing days are overwritten, new days are
/// added, days not in the file are left untouched).
class ExportImportService {
  const ExportImportService();

  // ── Export ───────────────────────────────────────────────────────────────

  Future<void> export(List<DayEntry> entries) async {
    final payload = {
      'version': 1,
      'app': 'dont_drink',
      'exported_at': DateOnly.keyFor(DateTime.now()),
      'entry_count': entries.length,
      'entries': entries.map((e) => e.toMap()).toList(),
    };

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

  /// Prompts the user to pick a backup file and upserts all entries found in
  /// it into [repository]. Returns an [ImportResult] describing what happened.
  Future<ImportResult> import(EntryRepository repository) async {
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

    // Parse and validate JSON.
    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return const ImportError('The selected file is not valid JSON.');
    }

    if (payload['app'] != 'dont_drink') {
      return const ImportError(
          "This file doesn't look like a Don't Drink backup.");
    }

    final rawEntries = payload['entries'];
    if (rawEntries is! List) {
      return const ImportError('Backup file is missing the entries list.');
    }

    // Upsert every entry.
    int count = 0;
    try {
      for (final raw in rawEntries) {
        if (raw is! Map<String, dynamic>) continue;
        final entry = DayEntry.fromMap(Map<String, Object?>.from(raw));
        await repository.upsert(entry);
        count++;
      }
    } catch (e) {
      return ImportError('Import failed after $count entries: $e');
    }

    return ImportSuccess(count);
  }
}

