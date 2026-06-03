import 'package:dont_drink/core/models/achievement.dart';

/// The full ordered list of streak achievements.
///
/// Milestones at 30, 100 and 365 days are flagged legendary so the UI can fire
/// a confetti celebration when they unlock.
const List<Achievement> kAchievements = [
  Achievement(
    id: 'day_1',
    dayThreshold: 1,
    title: 'Better Liver Begins',
    description: 'Your body already starts recovering from alcohol.',
  ),
  Achievement(
    id: 'day_3',
    dayThreshold: 3,
    title: 'Better Hydration',
    description: 'Your skin and hair can begin retaining moisture better.',
  ),
  Achievement(
    id: 'day_7',
    dayThreshold: 7,
    title: 'Better Sleep',
    description: 'Sleep quality often improves after a week alcohol-free.',
  ),
  Achievement(
    id: 'day_14',
    dayThreshold: 14,
    title: 'More Energy',
    description: 'Many people report improved energy and concentration.',
  ),
  Achievement(
    id: 'day_30',
    dayThreshold: 30,
    title: 'One Month Strong',
    description: 'Significant improvements in sleep, mood, and recovery.',
    emoji: '🌟',
    isLegendary: true,
  ),
  Achievement(
    id: 'day_60',
    dayThreshold: 60,
    title: 'Mental Clarity',
    description: 'Cognitive performance may improve noticeably.',
  ),
  Achievement(
    id: 'day_90',
    dayThreshold: 90,
    title: 'New Lifestyle',
    description: 'Habits become easier to maintain after 90 days.',
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
    title: 'One Year Alcohol-Free',
    description: 'A legendary achievement. One full year of better days.',
    emoji: '👑',
    isLegendary: true,
  ),
];
