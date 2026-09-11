import 'dart:math' as math;

import 'package:dont_drink/core/theme/app_colors.dart';
import 'package:dont_drink/data/static/facts_data.dart';
import 'package:dont_drink/ui/widgets/app_card.dart';
import 'package:dont_drink/ui/widgets/section_header.dart';
import 'package:dont_drink/viewmodels/tracker_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Educational facts for the active mode: a rotating "fact of the day" plus
/// browsable lists of harms and benefits.
class FactsScreen extends StatefulWidget {
  const FactsScreen({super.key});

  @override
  State<FactsScreen> createState() => _FactsScreenState();
}

class _FactsScreenState extends State<FactsScreen> {
  Fact? _factOfDay;
  List<Fact>? _factOfDayPack;

  /// Deterministic per-day pick so the "fact of the day" is stable for the day
  /// but changes each day.
  Fact _pickDailyFact(List<Fact> facts) {
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return facts[dayOfYear % facts.length];
  }

  void _shuffle(List<Fact> facts) {
    setState(() {
      _factOfDay = facts[math.Random().nextInt(facts.length)];
      _factOfDayPack = facts;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pack = context.watch<TrackerViewModel>().mode.content;

    if (!pack.hasFacts) {
      return const Scaffold(
        body: Center(child: Text('This mode has no facts yet.')),
      );
    }

    // Re-pick the fact of the day whenever the active mode's fact pack
    // changes (e.g. after a mode switch), so a stale fact from the previous
    // mode is never shown.
    if (_factOfDay == null || !identical(_factOfDayPack, pack.facts)) {
      _factOfDay = _pickDailyFact(pack.facts);
      _factOfDayPack = pack.facts;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Facts')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const SectionHeader('Fact of the Day'),
            _FactOfDayCard(
              fact: _factOfDay!,
              onShuffle: () => _shuffle(pack.facts),
            ),
            const SizedBox(height: 24),
            SectionHeader(pack.harmsTitle),
            for (final fact in pack.harms) _FactTile(fact: fact),
            const SizedBox(height: 24),
            SectionHeader(pack.benefitsTitle),
            for (final fact in pack.benefits) _FactTile(fact: fact),
          ],
        ),
      ),
    );
  }
}

class _FactOfDayCard extends StatelessWidget {
  const _FactOfDayCard({required this.fact, required this.onShuffle});

  final Fact fact;
  final VoidCallback onShuffle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: fact.isHarm
              ? [Color(0xFFF44336), Color(0xFFC62828)]
              : [AppColors.green, AppColors.brand],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                fact.isHarm ? '⚠️  Did you know?' : '✨  Good news',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                onPressed: onShuffle,
                icon: const Icon(Icons.shuffle, color: Colors.white),
                tooltip: 'Show another',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            fact.text,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FactTile extends StatelessWidget {
  const _FactTile({required this.fact});

  final Fact fact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = fact.isHarm ? const Color(0xFFF44336) : AppColors.green;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              fact.isHarm
                  ? Icons.remove_circle_outline
                  : Icons.check_circle_outline,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
                child: Text(fact.text, style: theme.textTheme.bodyLarge)),
          ],
        ),
      ),
    );
  }
}
