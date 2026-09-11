import 'package:dont_drink/core/models/achievement.dart';
import 'package:dont_drink/data/static/facts_data.dart';
import 'package:dont_drink/data/static/recovery_timeline_data.dart';
import 'package:flutter/foundation.dart';

/// The educational and motivational content belonging to one tracking mode.
///
/// Every list defaults to empty: a user-created custom mode has no facts and
/// no recovery timeline, and the UI hides those sections rather than showing
/// alcohol copy under a mode about something else.
@immutable
class ContentPack {
  const ContentPack({
    this.achievements = const [],
    this.facts = const [],
    this.recoveryMilestones = const [],
    this.motivations = const [],
    this.harmsTitle = 'Harms',
    this.benefitsTitle = 'Benefits',
    this.factsSubtitle = 'Harms & benefits',
    this.recoverySubtitle = 'What you gain over time',
  });

  final List<Achievement> achievements;
  final List<Fact> facts;
  final List<RecoveryMilestone> recoveryMilestones;
  final List<String> motivations;

  /// Section header for the "harm" half of the Facts screen.
  final String harmsTitle;

  /// Section header for the "benefit" half of the Facts screen.
  final String benefitsTitle;

  /// Subtitle for the Facts row on the More screen.
  final String factsSubtitle;

  /// Subtitle for the Recovery row on the More screen.
  final String recoverySubtitle;

  bool get hasFacts => facts.isNotEmpty;
  bool get hasRecovery => recoveryMilestones.isNotEmpty;

  List<Fact> get harms => facts.where((f) => f.isHarm).toList();
  List<Fact> get benefits => facts.where((f) => !f.isHarm).toList();

  /// Groups [recoveryMilestones] by tier, preserving order.
  Map<RecoveryTier, List<RecoveryMilestone>> get recoveryByTier => {
        for (final tier in RecoveryTier.values)
          tier: recoveryMilestones.where((m) => m.tier == tier).toList(),
      };
}
