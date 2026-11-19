import 'package:dont_drink/ui/yearly/yearly_screen.dart';
import 'package:flutter/material.dart';

/// [YearOverview] on a page of its own, laid out as the dashboard lays it out
/// (16px gutters, inside a scroll view), without the rest of the dashboard
/// around it — so year tests are not about the streak card or the month.
class YearPage extends StatelessWidget {
  const YearPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: const [YearOverview()],
        ),
      );
}
