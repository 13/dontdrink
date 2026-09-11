import 'package:dont_drink/core/models/content_pack.dart';
import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/core/models/tracked_level.dart';
import 'package:dont_drink/data/static/achievements_data.dart';
import 'package:dont_drink/data/static/facts_data.dart';
import 'package:dont_drink/data/static/motivation_data.dart';
import 'package:dont_drink/data/static/recovery_timeline_data.dart';
import 'package:flutter/material.dart';

/// Don't Drink's level scale. These integers are what the app has persisted
/// since version 1 — they must not change.
const List<TrackedLevel> kDontDrinkLevels = [
  TrackedLevel(
    value: 0,
    label: 'No Drinks',
    shortLabel: 'None',
    meaning: '0 alcoholic drinks',
    color: Color(0xFF4CAF50), // Green
    emoji: '💚',
    isClean: true,
  ),
  TrackedLevel(
    value: 1,
    label: '1–2 Drinks',
    shortLabel: 'Light',
    meaning: 'Light drinking',
    color: Color(0xFFFFC107), // Yellow / Amber
    emoji: '🟡',
  ),
  TrackedLevel(
    value: 2,
    label: '3–5 Drinks',
    shortLabel: 'Moderate',
    meaning: 'Moderate drinking',
    color: Color(0xFFFF9800), // Orange
    emoji: '🟠',
  ),
  TrackedLevel(
    value: 3,
    label: '6+ Drinks',
    shortLabel: 'Heavy',
    meaning: 'Heavy drinking',
    color: Color(0xFFF44336), // Red
    emoji: '🔴',
  ),
  TrackedLevel(
    value: 4,
    label: 'Blackout',
    shortLabel: 'Blackout',
    meaning: 'Extreme drinking / memory loss',
    color: Color(0xFF000000), // Black
    emoji: '⚫',
  ),
];

const ModeDefinition kDontDrinkMode = ModeDefinition(
  id: 'dont_drink',
  name: "Don't Drink",
  emoji: '🍺',
  cleanDayLabel: 'Alcohol-free',
  levels: kDontDrinkLevels,
  content: ContentPack(
    achievements: kAchievements,
    facts: kAllFacts,
    recoveryMilestones: kRecoveryTimeline,
    motivations: kMotivations,
    harmsTitle: 'Alcohol Harms',
    benefitsTitle: 'Benefits of Not Drinking',
    factsSubtitle: 'Harms of alcohol & benefits of quitting',
    recoverySubtitle: 'What your body gains over time',
  ),
);
