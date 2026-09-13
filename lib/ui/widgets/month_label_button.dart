import 'package:dont_drink/core/utils/date_utils.dart';
import 'package:dont_drink/ui/widgets/month_picker_dialog.dart';
import 'package:dont_drink/viewmodels/tracker_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// The "August 2026" heading, as a button that opens the month picker.
///
/// Both the dashboard's calendar section and the calendar screen show this
/// label, so the tap target lives here rather than being wired up twice.
class MonthLabelButton extends StatelessWidget {
  const MonthLabelButton({super.key, required this.month, this.style});

  final DateTime month;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final label =
        DateFormat.yMMMM(Localizations.localeOf(context).toString())
            .format(month);

    return TextButton(
      onPressed: () => _pick(context),
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      child: Text(label, textAlign: TextAlign.center, style: style),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final vm = context.read<TrackerViewModel>();
    final picked = await MonthPickerDialog.show(
      context,
      initialMonth: DateOnly.firstOfMonth(month),
      monthsWithData: vm.monthsWithData,
      firstMonth: vm.firstLoggedMonth,
    );
    if (picked != null) vm.showMonth(picked);
  }
}
