import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/core/models/tracked_level.dart';
import 'package:dont_drink/core/utils/date_utils.dart';

/// A single logged day. Exactly one entry can exist per calendar date per mode.
class DayEntry {
  DayEntry({
    required this.modeId,
    required this.date,
    required this.level,
    this.note,
    this.updatedAt,
  });

  /// Which tracking mode this entry belongs to.
  final String modeId;

  /// The calendar day this entry belongs to (time component is ignored).
  final DateTime date;

  /// The status logged for [date].
  final TrackedLevel level;

  /// Optional free-text note.
  final String? note;

  /// When this entry was last saved.
  final DateTime? updatedAt;

  /// Date key in `yyyy-MM-dd` form — half of the composite primary key.
  String get dateKey => DateOnly.keyFor(date);

  DayEntry copyWith({
    String? modeId,
    DateTime? date,
    TrackedLevel? level,
    String? note,
    DateTime? updatedAt,
  }) {
    return DayEntry(
      modeId: modeId ?? this.modeId,
      date: date ?? this.date,
      level: level ?? this.level,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'mode_id': modeId,
      'date_key': dateKey,
      'level': level.value,
      'note': note,
      'updated_at': (updatedAt ?? DateTime.now()).millisecondsSinceEpoch,
    };
  }

  /// Rebuild an entry from a database row. [mode] is required because a level
  /// integer only has meaning within its own mode.
  factory DayEntry.fromMap(Map<String, Object?> map, ModeDefinition mode) {
    final rawModeId = map['mode_id'];
    return DayEntry(
      modeId: rawModeId is String ? rawModeId : mode.id,
      date: DateOnly.parseKey(map['date_key'] as String),
      level: mode.levelForValue(map['level'] as int),
      note: map['note'] as String?,
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}
