import 'package:dont_drink/core/models/tracked_level.dart';
import 'package:dont_drink/core/utils/date_utils.dart';
import 'package:dont_drink/l10n/app_localizations.dart';
import 'package:dont_drink/services/achievement_service.dart';
import 'package:dont_drink/services/day_feedback.dart';
import 'package:dont_drink/ui/widgets/achievement_unlock_dialog.dart';
import 'package:dont_drink/ui/widgets/day_feedback_dialog.dart';
import 'package:dont_drink/viewmodels/tracker_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// What a log produced, handed back to whoever opened the sheet so the
/// reaction outlives the sheet's own route.
class _LogOutcome {
  const _LogOutcome({
    required this.earns,
    required this.feedback,
    required this.streak,
    required this.badgesEarned,
  });

  final List<AchievementEarn> earns;
  final DayFeedback? feedback;
  final int streak;
  final int badgesEarned;
}

/// Bottom sheet for logging or editing a single day's drink status.
///
/// Presents the active mode's levels; tapping one saves instantly and
/// (when a new achievement is crossed) shows the unlock celebration.
class DayEntrySheet extends StatelessWidget {
  const DayEntrySheet({super.key, required this.date});

  final DateTime date;

  /// Show the sheet for [date]. Returns after it is dismissed, and after any
  /// dialog the log deserved has been dismissed too.
  ///
  /// The sheet hands its outcome back rather than putting the dialog up
  /// itself: its own context dies with its route, and the caller's outlives
  /// both, which is what `showDialog` needs to find a Navigator.
  static Future<void> show(BuildContext context, DateTime date) async {
    final outcome = await showModalBottomSheet<_LogOutcome>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => DayEntrySheet(date: date),
    );

    if (outcome == null || !context.mounted) return;

    if (outcome.earns.isNotEmpty) {
      await AchievementUnlockDialog.show(context, outcome.earns);
    } else if (outcome.feedback != null) {
      await DayFeedbackDialog.show(
        context,
        feedback: outcome.feedback!,
        streak: outcome.streak,
        badgesEarned: outcome.badgesEarned,
        variant: feedbackVariant(date, DayFeedbackDialog.variantCount),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<TrackerViewModel>();
    final mode = vm.mode;
    final normalized = DateOnly.normalize(date);
    final existing = vm.entryFor(normalized);
    final isToday = DateOnly.isSameDay(normalized, DateTime.now());

    return SafeArea(
      child: SingleChildScrollView(
        // A mode with five levels plus the clear-day button does not fit a
        // short screen — a small phone in landscape, or any phone at a large
        // text scale — and a Column would simply clip the bottom option.
        padding: EdgeInsets.fromLTRB(
            20, 4, 20, 24 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isToday ? l10n.dashboardHowDidTodayGo : l10n.sheetLogThisDay,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE, MMMM d, y',
                      Localizations.localeOf(context).toString())
                  .format(normalized),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            for (final level in mode.levels)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _LevelOption(
                  level: level,
                  selected: existing?.level == level,
                  onTap: () => _save(context, normalized, level),
                ),
              ),
            if (existing != null) ...[
              const SizedBox(height: 4),
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    await context
                        .read<TrackerViewModel>()
                        .clearDay(normalized);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l10n.sheetClearDay),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save(
      BuildContext context, DateTime date, TrackedLevel level) async {
    final vm = context.read<TrackerViewModel>();
    final navigator = Navigator.of(context);
    final changed = await vm.logDay(date, level);
    final earns = vm.pendingEarns;
    vm.clearPendingEarns();

    final outcome = _LogOutcome(
      earns: earns,
      feedback: feedbackFor(
        isToday: DateOnly.isSameDay(date, DateTime.now()),
        isClean: level.isClean,
        earnedBadge: earns.isNotEmpty,
        changed: changed,
      ),
      streak: vm.stats.currentStreak,
      badgesEarned: vm.totalEarns,
    );

    if (!navigator.mounted) return;
    navigator.pop(outcome);
  }
}

class _LevelOption extends StatelessWidget {
  const _LevelOption({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final TrackedLevel level;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? level.color.withValues(alpha: 0.16)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? level.color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: level.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      level.label,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      level.meaning,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: level.color)
              else
                Icon(Icons.circle_outlined,
                    color: theme.colorScheme.outlineVariant),
            ],
          ),
        ),
      ),
    );
  }
}
