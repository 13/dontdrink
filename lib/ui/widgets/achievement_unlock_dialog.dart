import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:dont_drink/core/models/achievement.dart';
import 'package:dont_drink/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Celebration dialog shown when one or more achievements unlock.
///
/// Legendary milestones (30/90/180/365 days) fire confetti.
class AchievementUnlockDialog extends StatefulWidget {
  const AchievementUnlockDialog({super.key, required this.achievements});

  final List<Achievement> achievements;

  static Future<void> show(
      BuildContext context, List<Achievement> achievements) {
    if (achievements.isEmpty) return Future.value();
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AchievementUnlockDialog(achievements: achievements),
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

  bool get _isLegendary => widget.achievements.any((a) => a.isLegendary);

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
                    'Achievement Unlocked!',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.brand,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final a in widget.achievements) _Badge(achievement: a),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Keep going'),
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
            AppColors.yellow,
            AppColors.orange,
            AppColors.brand,
          ],
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
        ],
      ),
    );
  }
}
