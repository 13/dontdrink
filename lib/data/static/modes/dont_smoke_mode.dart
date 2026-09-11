import 'package:dont_drink/core/models/achievement.dart';
import 'package:dont_drink/core/models/content_pack.dart';
import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/core/models/tracked_level.dart';
import 'package:dont_drink/data/static/facts_data.dart';
import 'package:dont_drink/data/static/recovery_timeline_data.dart';
import 'package:flutter/material.dart';

const List<TrackedLevel> kDontSmokeLevels = [
  TrackedLevel(
    value: 0,
    label: 'No Cigarettes',
    shortLabel: 'None',
    meaning: '0 cigarettes',
    color: Color(0xFF4CAF50),
    emoji: '💚',
    isClean: true,
  ),
  TrackedLevel(
    value: 1,
    label: '1–5 Cigarettes',
    shortLabel: 'Light',
    meaning: 'A few throughout the day',
    color: Color(0xFFFFC107),
    emoji: '🟡',
  ),
  TrackedLevel(
    value: 2,
    label: '6–15 Cigarettes',
    shortLabel: 'Moderate',
    meaning: 'Around half a pack',
    color: Color(0xFFFF9800),
    emoji: '🟠',
  ),
  TrackedLevel(
    value: 3,
    label: '16+ Cigarettes',
    shortLabel: 'Heavy',
    meaning: 'A pack or more',
    color: Color(0xFFF44336),
    emoji: '🔴',
  ),
  TrackedLevel(
    value: 4,
    label: 'Chain Smoking',
    shortLabel: 'Binge',
    meaning: 'Continuous, one after another',
    color: Color(0xFF000000),
    emoji: '⚫',
  ),
];

const List<Achievement> _achievements = [
  Achievement(
    id: 'dont_smoke.day_1',
    dayThreshold: 1,
    title: 'Carbon Monoxide Drops',
    description: 'Within a day your blood oxygen starts returning to normal.',
  ),
  Achievement(
    id: 'dont_smoke.day_3',
    dayThreshold: 3,
    title: 'Nicotine Cleared',
    description: 'Nicotine has left your body. Cravings peak and then fall.',
  ),
  Achievement(
    id: 'dont_smoke.day_7',
    dayThreshold: 7,
    title: 'Taste & Smell Return',
    description: 'Damaged nerve endings begin to recover within the week.',
  ),
  Achievement(
    id: 'dont_smoke.day_14',
    dayThreshold: 14,
    title: 'Easier Breathing',
    description: 'Lung function and circulation measurably improve.',
  ),
  Achievement(
    id: 'dont_smoke.day_30',
    dayThreshold: 30,
    title: 'One Month Smoke-Free',
    description: 'Coughing and shortness of breath keep decreasing.',
    emoji: '🌟',
    isLegendary: true,
  ),
  Achievement(
    id: 'dont_smoke.day_60',
    dayThreshold: 60,
    title: 'Cilia Regrowing',
    description: 'Your lungs are clearing themselves far more effectively.',
  ),
  Achievement(
    id: 'dont_smoke.day_90',
    dayThreshold: 90,
    title: 'New Lifestyle',
    description: 'Lung function can be up to 30% better than when you quit.',
    emoji: '✨',
    isLegendary: true,
  ),
  Achievement(
    id: 'dont_smoke.day_180',
    dayThreshold: 180,
    title: 'Half-Year Champion',
    description: 'Six months without a cigarette. Remarkable consistency.',
    emoji: '🥇',
    isLegendary: true,
  ),
  Achievement(
    id: 'dont_smoke.day_365',
    dayThreshold: 365,
    title: 'One Year Smoke-Free',
    description: 'Your risk of heart disease is now about half a smoker\'s.',
    emoji: '👑',
    isLegendary: true,
  ),
];

const List<Fact> _facts = [
  Fact(text: 'Smoking damages nearly every organ in the body.', isHarm: true),
  Fact(text: 'Tobacco smoke carries around 70 known carcinogens.', isHarm: true),
  Fact(text: 'Smoking narrows blood vessels and raises blood pressure.', isHarm: true),
  Fact(text: 'Smokers get respiratory infections more often.', isHarm: true),
  Fact(text: 'Smoking accelerates skin ageing and wrinkling.', isHarm: true),
  Fact(text: 'Nicotine dependence builds within days of regular use.', isHarm: true),
  Fact(text: 'Smoking slows wound healing after injury or surgery.', isHarm: true),
  Fact(text: 'Secondhand smoke harms the people around you.', isHarm: true),
  Fact(text: 'Smoking reduces stamina and athletic performance.', isHarm: true),
  Fact(text: 'Food tastes better again.', isHarm: false),
  Fact(text: 'Easier breathing and less coughing.', isHarm: false),
  Fact(text: 'Better circulation to hands and feet.', isHarm: false),
  Fact(text: 'Clothes, hair and home stop smelling of smoke.', isHarm: false),
  Fact(text: 'Significant money saved every week.', isHarm: false),
  Fact(text: 'Lower risk of heart attack and stroke.', isHarm: false),
  Fact(text: 'Improved fertility and pregnancy outcomes.', isHarm: false),
  Fact(text: 'Whiter teeth and healthier gums.', isHarm: false),
  Fact(text: 'More energy for exercise.', isHarm: false),
];

const List<RecoveryMilestone> _recovery = [
  RecoveryMilestone(
    afterHours: 12,
    tier: RecoveryTier.bronze,
    name: 'Oxygen Returns',
    label: '12 Hours',
    icon: Icons.air,
    benefits: [
      'Carbon monoxide in your blood drops to a normal level.',
      'Oxygen reaches your organs more effectively.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 72,
    tier: RecoveryTier.bronze,
    name: 'Nicotine Free',
    label: 'Day 3',
    icon: Icons.bolt_outlined,
    benefits: [
      'All nicotine has left your body.',
      'Cravings peak here and then begin to fade.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 24 * 14,
    tier: RecoveryTier.silver,
    name: 'Breathing Easier',
    label: 'Week 2',
    icon: Icons.favorite_outline,
    benefits: [
      'Circulation improves and walking becomes easier.',
      'Lung function begins to increase.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 24 * 90,
    tier: RecoveryTier.silver,
    name: 'Clearer Lungs',
    label: 'Month 3',
    icon: Icons.health_and_safety_outlined,
    benefits: [
      'Cilia regrow, clearing mucus and cutting infection risk.',
      'Coughing and shortness of breath decrease markedly.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 24 * 365,
    tier: RecoveryTier.gold,
    name: 'Halved Heart Risk',
    label: 'Year 1',
    icon: Icons.monitor_heart_outlined,
    benefits: [
      'Excess risk of coronary heart disease is about half a smoker\'s.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 24 * 365 * 5,
    tier: RecoveryTier.diamond,
    name: 'Stroke Risk Normalised',
    label: 'Year 5',
    icon: Icons.psychology_outlined,
    benefits: [
      'Stroke risk can fall to that of a non-smoker.',
      'Risk of mouth, throat and bladder cancer is halved.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 24 * 365 * 10,
    tier: RecoveryTier.diamond,
    name: 'Clean Slate',
    label: 'Year 10',
    icon: Icons.verified,
    benefits: [
      'Risk of dying from lung cancer is about half that of a smoker.',
    ],
  ),
];

const List<String> _motivations = [
  'Every smoke-free day is progress.',
  'The craving passes whether you smoke or not.',
  'Your lungs are already repairing themselves.',
  'You are not giving something up — you are getting something back.',
  'One day at a time is still moving forward.',
  'Breathe. That feeling is your body recovering.',
  'Nobody ever regretted the cigarette they did not smoke.',
  'Small daily choices. Big long-term changes.',
  'Discomfort is temporary. Pride lasts.',
  'You did not come this far to only come this far.',
];

const ModeDefinition kDontSmokeMode = ModeDefinition(
  id: 'dont_smoke',
  name: "Don't Smoke",
  emoji: '🚭',
  cleanDayLabel: 'Smoke-free',
  levels: kDontSmokeLevels,
  content: ContentPack(
    achievements: _achievements,
    facts: _facts,
    recoveryMilestones: _recovery,
    motivations: _motivations,
    harmsTitle: 'Smoking Harms',
    benefitsTitle: 'Benefits of Quitting',
    factsSubtitle: 'Harms of smoking & benefits of quitting',
    recoverySubtitle: 'What your lungs gain over time',
  ),
);
