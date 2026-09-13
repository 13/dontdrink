import 'package:dont_drink/core/models/day_entry.dart';
import 'package:dont_drink/core/utils/date_utils.dart';
import 'package:dont_drink/l10n/app_localizations.dart';
import 'package:dont_drink/ui/widgets/app_card.dart';
import 'package:dont_drink/ui/widgets/day_entry_sheet.dart';
import 'package:dont_drink/viewmodels/tracker_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Everything written down, newest first.
///
/// Notes could be written and were marked on the calendar, but could not be
/// read anywhere: finding what you wrote meant opening days one at a time
/// until you hit one. This is the other half of that feature.
class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final vm = context.watch<TrackerViewModel>();
    final locale = Localizations.localeOf(context).toString();

    final noted = [
      for (final entry in vm.allEntries)
        if (entry.note != null && entry.note!.trim().isNotEmpty) entry,
    ].reversed.toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notesTitle)),
      body: SafeArea(
        child: noted.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    l10n.notesEmpty,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                itemCount: noted.length,
                itemBuilder: (context, i) =>
                    _NoteTile(entry: noted[i], locale: locale),
              ),
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.entry, required this.locale});

  final DayEntry entry;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => DayEntrySheet.show(context, entry.date),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: entry.level.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat.yMMMMd(locale)
                        .format(DateOnly.normalize(entry.date)),
                    style: theme.textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    entry.level.shortLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(entry.note!.trim(), style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
