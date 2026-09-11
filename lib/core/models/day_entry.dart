import 'package:dont_drink/core/models/drink_level.dart';
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
  final DrinkLevel level;

  /// Optional free-text note.
  final String? note;

  /// When this entry was last saved.
  final DateTime? updatedAt;

  /// Date key in `yyyy-MM-dd` form — half of the composite primary key.
  String get dateKey => DateOnly.keyFor(date);

  DayEntry copyWith({
    String? modeId,
    DateTime? date,
    DrinkLevel? level,
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

  factory DayEntry.fromMap(Map<String, Object?> map) {
    return DayEntry(
      modeId: map['mode_id'] as String? ?? 'dont_drink',
      date: DateOnly.parseKey(map['date_key'] as String),
      level: DrinkLevel.fromValue(map['level'] as int),
      note: map['note'] as String?,
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}
