import 'package:dont_drink/core/models/achievement.dart';
import 'package:dont_drink/core/models/content_pack.dart';
import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/core/models/tracked_level.dart';
import 'package:dont_drink/data/static/facts_data.dart';
import 'package:dont_drink/data/static/recovery_timeline_data.dart';
import 'package:flutter/material.dart';

const List<TrackedLevel> kNoContactLevels = [
  TrackedLevel(
    value: 0,
    label: 'No Contact',
    shortLabel: 'Clean',
    meaning: 'A full day with no contact',
    color: Color(0xFF4CAF50),
    emoji: '💚',
    isClean: true,
  ),
  TrackedLevel(
    value: 1,
    label: 'Thought About It',
    shortLabel: 'Urge',
    meaning: 'The urge came, you did not act on it',
    color: Color(0xFFFFC107),
    emoji: '🟡',
  ),
  TrackedLevel(
    value: 2,
    label: 'Checked Their Profile',
    shortLabel: 'Checked',
    meaning: 'Looked them up without reaching out',
    color: Color(0xFFFF9800),
    emoji: '🟠',
  ),
  TrackedLevel(
    value: 3,
    label: 'Reached Out',
    shortLabel: 'Contact',
    meaning: 'Messaged, called, or met up',
    color: Color(0xFFF44336),
    emoji: '🔴',
  ),
];

const List<Achievement> _achievements = [
  Achievement(
    id: 'no_contact.day_1',
    dayThreshold: 1,
    title: 'The Decision',
    description: 'The hardest day is the one you have already finished.',
  ),
  Achievement(
    id: 'no_contact.day_3',
    dayThreshold: 3,
    title: 'Through the Peak',
    description: 'The urge is at its loudest around now — and you held.',
  ),
  Achievement(
    id: 'no_contact.day_7',
    dayThreshold: 7,
    title: 'One Week Clear',
    description: 'A full week of choosing your own peace.',
  ),
  Achievement(
    id: 'no_contact.day_14',
    dayThreshold: 14,
    title: 'Quieter Mind',
    description: 'The constant checking impulse starts to loosen its grip.',
  ),
  Achievement(
    id: 'no_contact.day_30',
    dayThreshold: 30,
    title: 'One Month Strong',
    description: 'Thirty days. Your days belong to you again.',
    emoji: '🌟',
    isLegendary: true,
  ),
  Achievement(
    id: 'no_contact.day_60',
    dayThreshold: 60,
    title: 'Clearer Perspective',
    description: 'Distance makes the situation far easier to see honestly.',
  ),
  Achievement(
    id: 'no_contact.day_90',
    dayThreshold: 90,
    title: 'New Normal',
    description: 'After 90 days, no contact stops feeling like an effort.',
    emoji: '✨',
    isLegendary: true,
  ),
  Achievement(
    id: 'no_contact.day_180',
    dayThreshold: 180,
    title: 'Half-Year Free',
    description: 'Six months of protecting your own wellbeing.',
    emoji: '🥇',
    isLegendary: true,
  ),
  Achievement(
    id: 'no_contact.day_365',
    dayThreshold: 365,
    title: 'One Year Free',
    description: 'A full year. You built a life that does not need them in it.',
    emoji: '👑',
    isLegendary: true,
  ),
];

const List<Fact> _facts = [
  Fact(text: 'Every check-in restarts the attachment cycle.', isHarm: true),
  Fact(text: 'Intermittent contact is the hardest pattern to let go of.', isHarm: true),
  Fact(text: 'Rumination keeps the stress response switched on.', isHarm: true),
  Fact(text: 'Checking their profile delays your own recovery.', isHarm: true),
  Fact(text: '"Just one message" usually resets the clock entirely.', isHarm: true),
  Fact(text: 'Hoping for closure from them keeps you waiting on them.', isHarm: true),
  Fact(text: 'Sleep and concentration suffer while the loop continues.', isHarm: true),
  Fact(text: 'The urge peaks and then passes — always.', isHarm: false),
  Fact(text: 'Emotional intensity fades a little more each week.', isHarm: false),
  Fact(text: 'Your attention returns to your own life.', isHarm: false),
  Fact(text: 'Sleep and appetite settle back down.', isHarm: false),
  Fact(text: 'Other relationships get the energy they deserve.', isHarm: false),
  Fact(text: 'Self-respect rebuilds with every day you hold.', isHarm: false),
  Fact(text: 'Clarity about what happened arrives with distance.', isHarm: false),
  Fact(text: 'You stop rehearsing conversations that never happen.', isHarm: false),
];

const List<RecoveryMilestone> _recovery = [
  RecoveryMilestone(
    afterHours: 24,
    tier: RecoveryTier.bronze,
    name: 'The Decision',
    label: 'Day 1',
    icon: Icons.flag_outlined,
    benefits: [
      'The loop is broken. Today is the first day it does not continue.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 72,
    tier: RecoveryTier.bronze,
    name: 'The Peak',
    label: 'Day 3',
    icon: Icons.trending_down,
    benefits: [
      'Urges are usually strongest around now.',
      'From here the intensity starts to fall.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 24 * 21,
    tier: RecoveryTier.silver,
    name: 'The Quiet',
    label: 'Week 3',
    icon: Icons.self_improvement,
    benefits: [
      'The impulse to check becomes noticeably less frequent.',
      'Sleep and concentration begin to settle.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 24 * 90,
    tier: RecoveryTier.silver,
    name: 'Perspective',
    label: 'Month 3',
    icon: Icons.visibility_outlined,
    benefits: [
      'Distance makes it far easier to see the situation clearly.',
      'Your own plans start filling the space.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 24 * 365,
    tier: RecoveryTier.gold,
    name: 'Your Own Life',
    label: 'Year 1',
    icon: Icons.wb_sunny_outlined,
    benefits: [
      'A year of days that were about you.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 24 * 365 * 2,
    tier: RecoveryTier.diamond,
    name: 'Closed Chapter',
    label: 'Year 2',
    icon: Icons.verified,
    benefits: [
      'The memory stops steering your decisions.',
    ],
  ),
];

const List<String> _motivations = [
  'The urge passes. You do not have to act on it.',
  'No contact is not punishment. It is protection.',
  'You do not need closure from someone who caused the wound.',
  'Checking sets the clock back. Not checking moves it forward.',
  'Your peace is worth more than the answer you want.',
  'Small daily choices. Big long-term changes.',
  'One day at a time is still moving forward.',
  'You are allowed to stop waiting.',
  'Discomfort is temporary. Pride lasts.',
  'You did not come this far to only come this far.',
];

const ModeDefinition kNoContactMode = ModeDefinition(
  id: 'no_contact',
  name: 'No Contact',
  emoji: '📵',
  cleanDayLabel: 'No-contact',
  levels: kNoContactLevels,
  content: ContentPack(
    achievements: _achievements,
    facts: _facts,
    recoveryMilestones: _recovery,
    motivations: _motivations,
    harmsTitle: 'Why Contact Hurts',
    benefitsTitle: 'Benefits of No Contact',
    factsSubtitle: 'Why contact hurts & what distance gives back',
    recoverySubtitle: 'What changes as the distance grows',
  ),
);
