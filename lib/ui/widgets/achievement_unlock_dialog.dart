import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:dont_drink/core/theme/app_colors.dart';
import 'package:dont_drink/l10n/app_localizations.dart';
import 'package:dont_drink/services/achievement_service.dart';
import 'package:flutter/material.dart';

/// Celebration dialog shown when one or more achievements are earned.
///
/// Badges are repeatable, so an earn carries its running total and the dialog
/// says which time this was. Legendary milestones (30/90/180/365 days) fire
/// confetti on every earn, not only the first.
class AchievementUnlockDialog extends StatefulWidget {
  const AchievementUnlockDialog({super.key, required this.earns});

  final List<AchievementEarn> earns;

  static Future<void> show(BuildContext context, List<AchievementEarn> earns) {
    if (earns.isEmpty) return Future.value();
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AchievementUnlockDialog(earns: earns),
    );
  }

  @override
  State<AchievementUnlockDialog> createState() =>
      _AchievementUnlockDialogState();
}

class _AchievementUnlockDialogState extends State<AchievementUnlockDialog>
    with SingleTickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _scale;

  bool get _isLegendary => widget.earns.any((e) => e.achievement.isLegendary);

  /// True when every badge in this batch had been earned before.
  bool get _allRepeats => widget.earns.every((e) => e.isRepeat);

  @override
  void initState() {
    super.initState();
    _confetti = ConfettiController(duration: const Duration(seconds: 3));
    _scale = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
    if (_isLegendary) _confetti.play();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _scale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: ScaleTransition(
            scale: CurvedAnimation(parent: _scale, curve: Curves.elasticOut),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _allRepeats ? l10n.unlockTitleRepeat : l10n.unlockTitle,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.brand,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final earn in widget.earns) _Badge(earn: earn),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.unlockKeepGoing),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ConfettiWidget(
          confettiController: _confetti,
          blastDirection: math.pi / 2,
          maxBlastForce: 20,
          minBlastForce: 8,
          emissionFrequency: 0.04,
          numberOfParticles: 18,
          gravity: 0.25,
          colors: const [
            AppColors.green,
            Color(0xFFFFC107),
            Color(0xFFFF9800),
            AppColors.brand,
          ],
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.earn});

  final AchievementEarn earn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final achievement = earn.achievement;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Text(achievement.emoji, style: const TextStyle(fontSize: 56)),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            achievement.description,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (earn.isRepeat) ...[
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                AppLocalizations.of(context).unlockRepeatChip(earn.count),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.brand,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

