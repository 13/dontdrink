import 'package:dont_drink/core/models/drink_level.dart';
import 'package:dont_drink/core/utils/date_utils.dart';

/// A single logged day. Exactly one entry can exist per calendar date.
class DayEntry {
  DayEntry({
    required this.date,
    required this.level,
    this.note,
    this.updatedAt,
  });

  /// The calendar day this entry belongs to (time component is ignored).
  final DateTime date;

  /// The drinking status logged for [date].
  final DrinkLevel level;

  /// Optional free-text note.
  final String? note;

  /// When this entry was last saved.
  final DateTime? updatedAt;

  /// Date key in `yyyy-MM-dd` form — the primary key in the database.
  String get dateKey => DateOnly.keyFor(date);

  DayEntry copyWith({
    DateTime? date,
    DrinkLevel? level,
    String? note,
    DateTime? updatedAt,
  }) {
    return DayEntry(
      date: date ?? this.date,
      level: level ?? this.level,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'date_key': dateKey,
      'level': level.value,
      'note': note,
      'updated_at': (updatedAt ?? DateTime.now()).millisecondsSinceEpoch,
    };
  }

  factory DayEntry.fromMap(Map<String, Object?> map) {
    return DayEntry(
      date: DateOnly.parseKey(map['date_key'] as String),
      level: DrinkLevel.fromValue(map['level'] as int),
      note: map['note'] as String?,
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}
