import 'dart:math' as math;

import 'package:dont_drink/core/theme/app_colors.dart';
import 'package:dont_drink/data/static/facts_data.dart';
import 'package:dont_drink/ui/widgets/app_card.dart';
import 'package:dont_drink/ui/widgets/section_header.dart';
import 'package:flutter/material.dart';

/// Educational facts: a rotating "fact of the day" plus browsable lists of
/// alcohol harms and benefits of not drinking.
class FactsScreen extends StatefulWidget {
  const FactsScreen({super.key});

  @override
  State<FactsScreen> createState() => _FactsScreenState();
}

class _FactsScreenState extends State<FactsScreen> {
  late Fact _factOfDay;

  @override
  void initState() {
    super.initState();
    _factOfDay = _pickDailyFact();
  }

  /// Deterministic per-day pick so the "fact of the day" is stable for the day
  /// but changes each day.
  Fact _pickDailyFact() {
    final dayOfYear =
        DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return kAllFacts[dayOfYear % kAllFacts.length];
  }

  void _shuffle() {
    setState(() {
      _factOfDay = kAllFacts[math.Random().nextInt(kAllFacts.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Facts')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const SectionHeader('Fact of the Day'),
            _FactOfDayCard(fact: _factOfDay, onShuffle: _shuffle),
            const SizedBox(height: 24),
            const SectionHeader('Alcohol Harms'),
            for (final fact in kAlcoholHarms)
              _FactTile(fact: fact),
            const SizedBox(height: 24),
            const SectionHeader('Benefits of Not Drinking'),
            for (final fact in kBenefits)
              _FactTile(fact: fact),
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
              ? [AppColors.red, Color(0xFFC62828)]
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
    final color = fact.isHarm ? AppColors.red : AppColors.green;
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
