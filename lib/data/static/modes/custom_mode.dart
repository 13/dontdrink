import 'package:dont_drink/core/models/achievement.dart';
import 'package:dont_drink/core/models/content_pack.dart';
import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/core/models/tracked_level.dart';
import 'package:flutter/material.dart';

/// The fixed scale every custom mode uses. There is no level editor.
const List<TrackedLevel> kCustomLevels = [
  TrackedLevel(
    value: 0,
    label: 'Clean Day',
    shortLabel: 'Clean',
    meaning: 'You held to it today',
    color: Color(0xFF4CAF50),
    emoji: '💚',
    isClean: true,
  ),
  TrackedLevel(
    value: 1,
    label: 'Slip',
    shortLabel: 'Slip',
    meaning: 'A small lapse, back on track',
    color: Color(0xFFFFC107),
    emoji: '🟡',
  ),
  TrackedLevel(
    value: 2,
    label: 'Relapse',
    shortLabel: 'Relapse',
    meaning: 'A full return to the habit',
    color: Color(0xFFF44336),
    emoji: '🔴',
  ),
];

/// Habit-neutral milestones. Ids are prefixed per mode by [customModeFrom].
const List<Achievement> _genericAchievements = [
  Achievement(
    id: 'day_1',
    dayThreshold: 1,
    title: 'First Day Down',
    description: 'The first day is the hardest one to start.',
  ),
  Achievement(
    id: 'day_3',
    dayThreshold: 3,
    title: 'Three Days In',
    description: 'Early urges usually peak around here — and you held.',
  ),
  Achievement(
    id: 'day_7',
    dayThreshold: 7,
    title: 'One Week Strong',
    description: 'A full week of choosing the harder right thing.',
  ),
  Achievement(
    id: 'day_14',
    dayThreshold: 14,
    title: 'Two Weeks',
    description: 'Long enough that the new pattern starts to feel real.',
  ),
  Achievement(
    id: 'day_30',
    dayThreshold: 30,
    title: 'One Month Strong',
    description: 'Thirty days of consistency. That is a real change.',
    emoji: '🌟',
    isLegendary: true,
  ),
  Achievement(
    id: 'day_60',
    dayThreshold: 60,
    title: 'Two Months',
    description: 'The effort required keeps dropping.',
  ),
  Achievement(
    id: 'day_90',
    dayThreshold: 90,
    title: 'New Lifestyle',
    description: 'Habits become much easier to maintain after 90 days.',
    emoji: '✨',
    isLegendary: true,
  ),
  Achievement(
    id: 'day_180',
    dayThreshold: 180,
    title: 'Half-Year Champion',
    description: 'Six months of choosing yourself. Remarkable consistency.',
    emoji: '🥇',
    isLegendary: true,
  ),
  Achievement(
    id: 'day_365',
    dayThreshold: 365,
    title: 'One Full Year',
    description: 'A legendary achievement. One full year of better days.',
    emoji: '👑',
    isLegendary: true,
  ),
];

const List<String> _genericMotivations = [
  'Every clean day is progress.',
  "Your future self benefits from today's decision.",
  'Streaks are built one day at a time.',
  'Progress matters more than perfection.',
  'You are stronger than a craving.',
  'Small daily choices. Big long-term changes.',
  'One day at a time is still moving forward.',
  'The best project you can work on is you.',
  'Discomfort is temporary. Pride lasts.',
  'You did not come this far to only come this far.',
];

/// Build a custom mode from its stored row.
///
/// Achievement ids are prefixed with [id] so they stay globally unique even
/// when several custom modes exist.
ModeDefinition customModeFrom({
  required String id,
  required String name,
  required String emoji,
}) {
  return ModeDefinition(
    id: id,
    name: name,
    emoji: emoji,
    cleanDayLabel: 'Clean',
    levels: kCustomLevels,
    isBuiltIn: false,
    content: ContentPack(
      achievements: [
        for (final a in _genericAchievements)
          Achievement(
            id: '$id.${a.id}',
            dayThreshold: a.dayThreshold,
            title: a.title,
            description: a.description,
            emoji: a.emoji,
            isLegendary: a.isLegendary,
          ),
      ],
      motivations: _genericMotivations,
      // No facts, no recovery timeline — the UI hides those sections.
    ),
  );
}
