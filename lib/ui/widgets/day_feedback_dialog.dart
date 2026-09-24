import 'package:dont_drink/core/theme/app_colors.dart';
import 'package:dont_drink/l10n/app_localizations.dart';
import 'package:dont_drink/services/day_feedback.dart';
import 'package:dont_drink/ui/motivation/motivation_screen.dart';
import 'package:flutter/material.dart';

/// The quiet counterpart to [AchievementUnlockDialog]: what a day gets when it
/// earned no badge.
///
/// Deliberately smaller than the unlock dialog — a short fade, no confetti, no
/// elastic bounce — because this appears on ordinary days and must not compete
/// with an actual milestone. It closes on a tap outside, so nothing here has
/// to be read before the app lets you go.
class DayFeedbackDialog extends StatelessWidget {
  const DayFeedbackDialog({
    super.key,
    required this.feedback,
    required this.streak,
    required this.badgesEarned,
    required this.variant,
  });

  final DayFeedback feedback;

  /// Current clean streak, shown in the cheer's title.
  final int streak;

  /// Badges earned so far, repeats included — the comfort message's one
  /// factual reassurance, and true because badges are never taken away.
  final int badgesEarned;

  /// Which wording to use, stable for the calendar day.
  final int variant;

  static Future<void> show(
    BuildContext context, {
    required DayFeedback feedback,
    required int streak,
    required int badgesEarned,
    required int variant,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => DayFeedbackDialog(
        feedback: feedback,
        streak: streak,
        badgesEarned: badgesEarned,
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

    final bodies = isCheer ? _cheerBodies(l10n) : _comfortBodies(l10n);
    final body = bodies[variant % bodies.length];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCheer ? '🌱' : '🫶',
              style: const TextStyle(fontSize: 36),
            ),
            const SizedBox(height: 12),
            Text(
              isCheer ? l10n.cheerTitle(streak) : l10n.comfortTitle,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            if (!isCheer) ...[
              const SizedBox(height: 10),
              Text(
                l10n.comfortKept(badgesEarned),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.brand,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            // An OverflowBar rather than a Row: the German boost label is long
            // enough to push the close button off the dialog, and here the
            // buttons stack instead.
            OverflowBar(
              alignment: MainAxisAlignment.end,
              overflowAlignment: OverflowBarAlignment.end,
              spacing: 8,
              overflowSpacing: 4,
              children: [
                if (!isCheer)
                  TextButton(
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
                    child: Text(l10n.comfortBoost),
                  ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(isCheer ? l10n.cheerClose : l10n.comfortClose),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
