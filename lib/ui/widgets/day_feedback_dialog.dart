import 'package:dont_drink/core/theme/app_colors.dart';
import 'package:dont_drink/l10n/app_localizations.dart';
import 'package:dont_drink/services/day_feedback.dart';
import 'package:dont_drink/ui/motivation/motivation_screen.dart';
import 'package:flutter/material.dart';

/// The quiet counterpart to [AchievementUnlockDialog]: what a day gets when it
/// earned no badge.
///
/// Deliberately smaller than the unlock dialog — a short fade and lift, no
/// confetti, no elastic bounce — because this appears on ordinary days and
/// must not compete with an actual milestone. It closes on a tap outside, so
/// nothing here has to be read before the app lets you go.
class DayFeedbackDialog extends StatelessWidget {
  const DayFeedbackDialog({
    super.key,
    required this.feedback,
    required this.streak,
    required this.badgesEarned,
    required this.bestStreak,
    required this.variant,
  });

  final DayFeedback feedback;

  /// Current clean streak, shown in the cheer's title.
  final int streak;

  /// Badges earned so far, repeats included — part of the comfort chip, and
  /// true because badges are never taken away.
  final int badgesEarned;

  /// Longest streak ever, the comfort chip's other half. A slip ends the
  /// current streak but never this one.
  final int bestStreak;

  /// Which wording to use, stable for the calendar day.
  final int variant;

  static Future<void> show(
    BuildContext context, {
    required DayFeedback feedback,
    required int streak,
    required int badgesEarned,
    required int bestStreak,
    required int variant,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => DayFeedbackDialog(
        feedback: feedback,
        streak: streak,
        badgesEarned: badgesEarned,
        bestStreak: bestStreak,
        variant: variant,
      ),
    );
  }

  /// The five rotating lines for each kind, in variant order.
  static List<String> _cheerBodies(AppLocalizations l10n) => [
        l10n.cheerBody0,
        l10n.cheerBody1,
        l10n.cheerBody2,
        l10n.cheerBody3,
        l10n.cheerBody4,
      ];

  static List<String> _comfortBodies(AppLocalizations l10n) => [
        l10n.comfortBody0,
        l10n.comfortBody1,
        l10n.comfortBody2,
        l10n.comfortBody3,
        l10n.comfortBody4,
      ];

  /// How many variants each kind has, so the caller can pick one without
  /// needing localizations.
  static const int variantCount = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isCheer = feedback == DayFeedback.cheer;
    // Teal for a good day, peach for a hard one: warm, not a warning.
    final tint = isCheer ? AppColors.brand : AppColors.warm;

    final bodies = isCheer ? _cheerBodies(l10n) : _comfortBodies(l10n);
    final body = bodies[variant % bodies.length];

    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration:
          reduceMotion ? Duration.zero : const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - t)),
          child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
        ),
      ),
      child: Dialog(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [tint.withValues(alpha: 0.16), tint.withValues(alpha: 0)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HeroEmoji(emoji: isCheer ? '🌱' : '🫶', tint: tint),
                const SizedBox(height: 20),
                Text(
                  isCheer ? l10n.cheerTitle(streak) : l10n.comfortTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                if (!isCheer && (badgesEarned > 0 || bestStreak > 0)) ...[
                  const SizedBox(height: 20),
                  _KeptChip(
                    badgesEarned: badgesEarned,
                    bestStreak: bestStreak,
                    tint: tint,
                  ),
                ],
                const SizedBox(height: 24),
                // Stacked full-width rather than side by side: the German
                // boost label alone is wider than a phone dialog.
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(isCheer ? l10n.cheerClose : l10n.comfortClose),
                  ),
                ),
                if (!isCheer) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        // Captured before the pop: afterwards this context is
                        // deactivated and cannot route anywhere.
                        final navigator = Navigator.of(context);
                        navigator.pop();
                        navigator.push(
                          MaterialPageRoute<void>(
                            builder: (_) => const MotivationScreen(),
                          ),
                        );
                      },
                      child: Text(
                        l10n.comfortBoost,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The dialog's emoji, set in a tinted disc with a soft glow.
class _HeroEmoji extends StatelessWidget {
  const _HeroEmoji({required this.emoji, required this.tint});

  final String emoji;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 76,
        height: 76,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: tint.withValues(alpha: 0.18),
          border: Border.all(color: tint.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: tint.withValues(alpha: 0.30),
              blurRadius: 28,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 36)),
      ),
    );
  }
}

/// What a slip does not take away: badges and the best streak, as numbers.
/// A part that is zero is left out rather than shown as nothing kept.
class _KeptChip extends StatelessWidget {
  const _KeptChip({
    required this.badgesEarned,
    required this.bestStreak,
    required this.tint,
  });

  final int badgesEarned;
  final int bestStreak;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final parts = [
      if (badgesEarned > 0) ('🏅', l10n.comfortKeptBadges(badgesEarned)),
      if (bestStreak > 0) ('🏆', l10n.comfortKeptBest(bestStreak)),
    ];
    final partStyle = theme.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
    );

    return Semantics(
      container: true,
      label: '${l10n.comfortKeptLabel}: '
          '${parts.map((p) => p.$2).join(', ')}',
      child: ExcludeSemantics(
        child: Column(
          children: [
            Text(
              l10n.comfortKeptLabel.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: tint,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: tint.withValues(alpha: 0.30)),
              ),
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 10,
                runSpacing: 4,
                children: [
                  for (final (i, (emoji, text)) in parts.indexed) ...[
                    if (i > 0)
                      Text('·',
                          style: partStyle?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    Text('$emoji $text', style: partStyle),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
