import 'package:dont_drink/core/models/content_pack.dart';
import 'package:dont_drink/core/models/tracked_level.dart';
import 'package:flutter/foundation.dart';

/// One tracking mode: what is being tracked, how a day is logged, and the
/// content shown while tracking it.
///
/// Built-in modes are `const` definitions in `lib/data/static/modes/`. Custom
/// modes are built from `modes` table rows and have [isBuiltIn] false.
@immutable
class ModeDefinition {
  const ModeDefinition({
    required this.id,
    required this.name,
    required this.emoji,
    required this.cleanDayLabel,
    required this.levels,
    required this.content,
    this.isBuiltIn = true,
  });

  /// Stable identifier persisted in `day_entries.mode_id`.
  final String id;

  /// Display name, e.g. "Don't Drink".
  final String name;

  /// Shown beside the name in the switcher and settings list.
  final String emoji;

  /// How a clean day is described in stats copy, e.g. "Alcohol-free".
  final String cleanDayLabel;

  /// The scale a day is logged on. Exactly one level has `isClean: true`,
  /// and it has `value: 0`.
  final List<TrackedLevel> levels;

  final ContentPack content;

  final bool isBuiltIn;

  /// The level that counts toward a streak.
  TrackedLevel get cleanLevel => levels.firstWhere((l) => l.isClean);

  /// Resolve a persisted integer back to a level. Unknown values fall back to
  /// the clean level rather than throwing, so a corrupt row cannot crash the
  /// app.
  TrackedLevel levelForValue(int value) => levels.firstWhere(
        (l) => l.value == value,
        orElse: () => cleanLevel,
      );

  /// Only a custom mode's name and emoji are editable.
  ModeDefinition copyWith({String? name, String? emoji}) => ModeDefinition(
        id: id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        cleanDayLabel: cleanDayLabel,
        levels: levels,
        content: content,
        isBuiltIn: isBuiltIn,
      );
}
