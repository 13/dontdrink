import 'package:dont_drink/core/models/drink_level.dart';
import 'package:dont_drink/core/utils/date_utils.dart';
import 'package:dont_drink/ui/widgets/achievement_unlock_dialog.dart';
import 'package:dont_drink/viewmodels/tracker_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Bottom sheet for logging or editing a single day's drink status.
///
/// Presents the five [DrinkLevel] options; tapping one saves instantly and
/// (when a new achievement is crossed) shows the unlock celebration.
class DayEntrySheet extends StatelessWidget {
  const DayEntrySheet({super.key, required this.date});

  final DateTime date;

  /// Show the sheet for [date]. Returns after it is dismissed.
  static Future<void> show(BuildContext context, DateTime date) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => DayEntrySheet(date: date),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = context.watch<TrackerViewModel>();
    final normalized = DateOnly.normalize(date);
    final existing = vm.entryFor(normalized);
    final isToday = DateOnly.isSameDay(normalized, DateTime.now());

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isToday ? 'How did today go?' : 'Log this day',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('EEEE, MMMM d, y').format(normalized),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            for (final level in DrinkLevel.values)
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
                  label: const Text('Clear this day'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save(
      BuildContext context, DateTime date, DrinkLevel level) async {
    final vm = context.read<TrackerViewModel>();
    await vm.logDay(date, level);
    final unlocks = vm.pendingUnlocks;
    vm.clearPendingUnlocks();

    if (!context.mounted) return;
    Navigator.of(context).pop();

    if (unlocks.isNotEmpty) {
      await AchievementUnlockDialog.show(context, unlocks);
    }
  }
}

class _LevelOption extends StatelessWidget {
  const _LevelOption({
    required this.level,
    required this.selected,
    required this.onTap,
  });

  final DrinkLevel level;
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
