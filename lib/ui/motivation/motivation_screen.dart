import 'dart:math' as math;

import 'package:dont_drink/core/theme/app_colors.dart';
import 'package:dont_drink/data/static/motivation_data.dart';
import 'package:flutter/material.dart';

/// Full-bleed swipeable motivation cards.
class MotivationScreen extends StatefulWidget {
  const MotivationScreen({super.key});

  @override
  State<MotivationScreen> createState() => _MotivationScreenState();
}

class _MotivationScreenState extends State<MotivationScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _gradients = <List<Color>>[
    [AppColors.brand, AppColors.brandDark],
    [AppColors.green, Color(0xFF2E7D32)],
    [Color(0xFF5C6BC0), Color(0xFF3949AB)],
    [AppColors.orange, Color(0xFFE65100)],
    [Color(0xFF26A69A), Color(0xFF00695C)],
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Motivation')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: kMotivations.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, index) {
                  final colors = _gradients[index % _gradients.length];
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: LinearGradient(
                          colors: colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.format_quote,
                              color: Colors.white70, size: 48),
                          const SizedBox(height: 24),
                          Text(
                            kMotivations[index],
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < kMotivations.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 20 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? AppColors.brand
                            : theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    final next = math.Random().nextInt(kMotivations.length);
                    _controller.animateToPage(
                      next,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Inspire me'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
