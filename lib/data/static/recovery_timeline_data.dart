import 'package:flutter/material.dart';

enum RecoveryTier {
  bronze,
  silver,
  gold,
  diamond;

  String get label => switch (this) {
        RecoveryTier.bronze => '🥉 Bronze — The Acute Phase',
        RecoveryTier.silver => '🥈 Silver — The Regeneration Phase',
        RecoveryTier.gold => '🥇 Gold — The Vitality Phase',
        RecoveryTier.diamond => '💎 Diamond — Long-Term Protection',
      };

  String get subtitle => switch (this) {
        RecoveryTier.bronze => 'Days 1 to 7',
        RecoveryTier.silver => 'Weeks 2 to Month 3',
        RecoveryTier.gold => 'Month 6 to Year 2',
        RecoveryTier.diamond => 'Year 5 and Beyond',
      };

  Color get color => switch (this) {
        RecoveryTier.bronze => const Color(0xFFCD7F32),
        RecoveryTier.silver => const Color(0xFF9E9E9E),
        RecoveryTier.gold => const Color(0xFFFFD700),
        RecoveryTier.diamond => const Color(0xFF64B5F6),
      };
}

class RecoveryMilestone {
  const RecoveryMilestone({
    required this.afterHours,
    required this.tier,
    required this.name,
    required this.label,
    required this.icon,
    required this.benefits,
  });

  /// Hours alcohol-free after which these benefits typically begin.
  final int afterHours;

  final RecoveryTier tier;

  /// Short punchy name, e.g. "The Baseline".
  final String name;

  /// Time label shown on the timeline, e.g. "Day 1".
  final String label;

  final IconData icon;

  /// One or two bullet-point descriptions of this milestone.
  final List<String> benefits;
}

const List<RecoveryMilestone> kRecoveryTimeline = [
  // ── Bronze ──────────────────────────────────────────────────────────────
  RecoveryMilestone(
    afterHours: 24,
    tier: RecoveryTier.bronze,
    name: 'The Baseline',
    label: 'Day 1',
    icon: Icons.water_drop_outlined,
    benefits: [
      'Blood alcohol level drops to zero.',
      'Immediate relief for your vital organs begins.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 72,
    tier: RecoveryTier.bronze,
    name: 'The Turning Point',
    label: 'Day 3',
    icon: Icons.healing_outlined,
    benefits: [
      'The peak of physical withdrawal passes.',
      'Shaking, sweating, and anxiety begin to fade.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 168,
    tier: RecoveryTier.bronze,
    name: 'The Energy Boost',
    label: 'Day 7',
    icon: Icons.bed_outlined,
    benefits: [
      'Sleep architecture stabilizes.',
      'You experience deep REM sleep and wake up refreshed.',
    ],
  ),

  // ── Silver ──────────────────────────────────────────────────────────────
  RecoveryMilestone(
    afterHours: 336, // 14 days
    tier: RecoveryTier.silver,
    name: 'The Clarity Effect',
    label: 'Week 2',
    icon: Icons.psychology_outlined,
    benefits: [
      'Brain fog lifts.',
      'Concentration, memory, and mental clarity improve significantly.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 672, // 28 days
    tier: RecoveryTier.silver,
    name: 'The Visual Glow-Up',
    label: 'Week 4',
    icon: Icons.face_retouching_natural,
    benefits: [
      'Skin hydrates fully, reducing redness and eye bags.',
      'Hair roots receive better nutrients.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 672, // 28 days (same window, separate milestone)
    tier: RecoveryTier.silver,
    name: 'The Weight Bonus',
    label: 'Week 4',
    icon: Icons.monitor_weight_outlined,
    benefits: [
      'Noticeable weight loss, especially around the abdomen.',
      'Empty liquid calories eliminated from your diet.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 720, // 30 days
    tier: RecoveryTier.silver,
    name: 'Brain Rewiring',
    label: 'Month 1',
    icon: Icons.hub_outlined,
    benefits: [
      'MRI scans show measurable volume increase in grey matter.',
      'New neuronal connections form as the brain rewires.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 1440, // 60 days
    tier: RecoveryTier.silver,
    name: 'Liver Reset',
    label: 'Month 2',
    icon: Icons.favorite_outline,
    benefits: [
      'The liver aggressively sheds accumulated fat.',
      'Early-stage fatty liver disease rapidly reverses.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 2160, // 90 days
    tier: RecoveryTier.silver,
    name: 'Hormone Balance',
    label: 'Month 3',
    icon: Icons.balance_outlined,
    benefits: [
      'Hormonal levels normalize.',
      'Sperm quality and ovulation cycles stabilize, restoring fertility.',
    ],
  ),

  // ── Gold ────────────────────────────────────────────────────────────────
  RecoveryMilestone(
    afterHours: 4380, // ~6 months
    tier: RecoveryTier.gold,
    name: 'Full Healing',
    label: 'Month 6',
    icon: Icons.healing,
    benefits: [
      'Alcohol-induced fatty liver disease is typically completely reversed.',
      'Applies to moderate-to-heavy former drinkers.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 4380,
    tier: RecoveryTier.gold,
    name: 'Peak Fitness',
    label: 'Month 6',
    icon: Icons.fitness_center_outlined,
    benefits: [
      'Muscle protein synthesis optimizes.',
      'Physical endurance and workout recovery reach maximum efficiency.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 8760, // 1 year
    tier: RecoveryTier.gold,
    name: 'Cardiovascular Shield',
    label: 'Year 1',
    icon: Icons.monitor_heart_outlined,
    benefits: [
      'Blood pressure and cholesterol stabilize.',
      'Your risk of suffering a fatal stroke drops significantly.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 17520, // 2 years
    tier: RecoveryTier.gold,
    name: 'Heart Restoration',
    label: 'Year 2',
    icon: Icons.favorite,
    benefits: [
      'The risk of developing long-term coronary heart disease is massively reduced.',
    ],
  ),

  // ── Diamond ─────────────────────────────────────────────────────────────
  RecoveryMilestone(
    afterHours: 43800, // 5 years
    tier: RecoveryTier.diamond,
    name: 'Cancer Risk Cut',
    label: 'Year 5',
    icon: Icons.shield_outlined,
    benefits: [
      'Your risk of cancers of the mouth, throat, and esophagus is cut in half.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 131400, // 15 years
    tier: RecoveryTier.diamond,
    name: 'Clean Slate',
    label: 'Year 15',
    icon: Icons.verified,
    benefits: [
      'Overall cancer and disease risk drops to a level nearly identical to a lifelong non-drinker.',
    ],
  ),
];

/// Groups [kRecoveryTimeline] by tier, preserving order.
Map<RecoveryTier, List<RecoveryMilestone>> get kRecoveryByTier {
  final map = <RecoveryTier, List<RecoveryMilestone>>{};
  for (final tier in RecoveryTier.values) {
    map[tier] = kRecoveryTimeline.where((m) => m.tier == tier).toList();
  }
  return map;
}
