import 'package:dont_drink/core/models/achievement.dart';
import 'package:dont_drink/core/models/content_pack.dart';
import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/core/models/tracked_level.dart';
import 'package:dont_drink/data/static/facts_data.dart';
import 'package:dont_drink/data/static/recovery_timeline_data.dart';
import 'package:dont_drink/l10n/content/content_strings.dart';

/// Rewrites a mode's text through a [ContentStrings] map.
///
/// The English definitions in `lib/data/static/` stay the source of truth for
/// structure *and* for English text; a translation replaces individual strings
/// by key and anything unkeyed stays as it is. Keys are derived from stable
/// identifiers — the mode id, a level's persisted value, an achievement id —
/// or, where the data has no id, from the item's index in its own list.
extension ModeLocalization on ModeDefinition {
  /// This mode's key prefix. Custom modes all share the generic "custom"
  /// content, so they share its translations too; their user-typed name and
  /// emoji are never translated.
  String get contentKey => isBuiltIn ? id : 'custom';

  ModeDefinition localized(ContentStrings s) {
    if (s.languageCode == 'en') return this;
    final key = contentKey;
    return ModeDefinition(
      id: id,
      name: isBuiltIn ? (s['mode.$key.name'] ?? name) : name,
      emoji: emoji,
      cleanDayLabel: s['mode.$key.cleanDayLabel'] ?? cleanDayLabel,
      levels: [for (final level in levels) _level(s, key, level)],
      content: _pack(s, key, content),
      isBuiltIn: isBuiltIn,
    );
  }
}

TrackedLevel _level(ContentStrings s, String modeKey, TrackedLevel level) {
  final key = 'level.$modeKey.${level.value}';
  return TrackedLevel(
    value: level.value,
    label: s['$key.label'] ?? level.label,
    shortLabel: s['$key.short'] ?? level.shortLabel,
    meaning: s['$key.meaning'] ?? level.meaning,
    color: level.color,
    emoji: level.emoji,
    isClean: level.isClean,
  );
}

ContentPack _pack(ContentStrings s, String modeKey, ContentPack pack) {
  return ContentPack(
    achievements: [
      for (final a in pack.achievements) _achievement(s, modeKey, a),
    ],
    facts: [
      for (var i = 0; i < pack.facts.length; i++)
        Fact(
          text: s['fact.$modeKey.$i'] ?? pack.facts[i].text,
          isHarm: pack.facts[i].isHarm,
        ),
    ],
    recoveryMilestones: [
      for (var i = 0; i < pack.recoveryMilestones.length; i++)
        _milestone(s, modeKey, i, pack.recoveryMilestones[i]),
    ],
    motivations: [
      for (var i = 0; i < pack.motivations.length; i++)
        s['motivation.$modeKey.$i'] ?? pack.motivations[i],
    ],
    harmsTitle: s['pack.$modeKey.harmsTitle'] ?? pack.harmsTitle,
    benefitsTitle: s['pack.$modeKey.benefitsTitle'] ?? pack.benefitsTitle,
    factsSubtitle: s['pack.$modeKey.factsSubtitle'] ?? pack.factsSubtitle,
    recoverySubtitle:
        s['pack.$modeKey.recoverySubtitle'] ?? pack.recoverySubtitle,
  );
}

Achievement _achievement(ContentStrings s, String modeKey, Achievement a) {
  // A custom mode prefixes its achievement ids with its own mode id
  // ("custom_1712...day_7"), so key off the last segment to keep one set of
  // translations for every custom mode.
  final suffix = a.id.split('.').last;
  final key = 'achv.$modeKey.$suffix';
  return Achievement(
    id: a.id,
    dayThreshold: a.dayThreshold,
    title: s['$key.title'] ?? a.title,
    description: s['$key.description'] ?? a.description,
    emoji: a.emoji,
    isLegendary: a.isLegendary,
  );
}

RecoveryMilestone _milestone(
  ContentStrings s,
  String modeKey,
  int index,
  RecoveryMilestone m,
) {
  final key = 'recovery.$modeKey.$index';
  return RecoveryMilestone(
    afterHours: m.afterHours,
    tier: m.tier,
    name: s['$key.name'] ?? m.name,
    label: s['$key.label'] ?? m.label,
    icon: m.icon,
    benefits: [
      for (var i = 0; i < m.benefits.length; i++)
        s['$key.benefit.$i'] ?? m.benefits[i],
    ],
  );
}

/// Every content key a mode uses, with its English text. The dump tool and the
/// parity test both build their expectations from this, so a key can never be
/// spelled one way here and another way in the translations.
Map<String, String> contentKeysFor(ModeDefinition mode) {
  final key = mode.contentKey;
  final out = <String, String>{};
  if (mode.isBuiltIn) out['mode.$key.name'] = mode.name;
  out['mode.$key.cleanDayLabel'] = mode.cleanDayLabel;

  for (final level in mode.levels) {
    final lk = 'level.$key.${level.value}';
    out['$lk.label'] = level.label;
    out['$lk.short'] = level.shortLabel;
    out['$lk.meaning'] = level.meaning;
  }

  final pack = mode.content;
  for (final a in pack.achievements) {
    final ak = 'achv.$key.${a.id.split('.').last}';
    out['$ak.title'] = a.title;
    out['$ak.description'] = a.description;
  }
  for (var i = 0; i < pack.facts.length; i++) {
    out['fact.$key.$i'] = pack.facts[i].text;
  }
  for (var i = 0; i < pack.motivations.length; i++) {
    out['motivation.$key.$i'] = pack.motivations[i];
  }
  for (var i = 0; i < pack.recoveryMilestones.length; i++) {
    final m = pack.recoveryMilestones[i];
    final rk = 'recovery.$key.$i';
    out['$rk.name'] = m.name;
    out['$rk.label'] = m.label;
    for (var b = 0; b < m.benefits.length; b++) {
      out['$rk.benefit.$b'] = m.benefits[b];
    }
  }

  if (pack.hasFacts) {
    out['pack.$key.harmsTitle'] = pack.harmsTitle;
    out['pack.$key.benefitsTitle'] = pack.benefitsTitle;
    out['pack.$key.factsSubtitle'] = pack.factsSubtitle;
  }
  if (pack.hasRecovery) {
    out['pack.$key.recoverySubtitle'] = pack.recoverySubtitle;
  }
  return out;
}
