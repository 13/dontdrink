import 'dart:async';

import 'package:dont_drink/core/theme/app_theme.dart';
import 'package:dont_drink/core/utils/date_utils.dart';
import 'package:dont_drink/l10n/app_localizations.dart';
import 'package:dont_drink/l10n/content/content_strings.dart';
import 'package:dont_drink/l10n/supported_locales.dart';
import 'package:dont_drink/ui/shell/home_shell.dart';
import 'package:dont_drink/ui/shell/reminder_sync.dart';
import 'package:dont_drink/viewmodels/mode_viewmodel.dart';
import 'package:dont_drink/viewmodels/settings_viewmodel.dart';
import 'package:dont_drink/viewmodels/tracker_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

class DontDrinkApp extends StatelessWidget {
  const DontDrinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select<SettingsViewModel, ThemeMode>(
      (vm) => vm.themeMode,
    );
    // null means "follow the system": MaterialApp then resolves the device
    // locale against supportedLocales and falls back to English.
    final locale = context.select<SettingsViewModel, Locale?>(
      (vm) => vm.locale,
    );

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: kSupportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const _ContentLanguage(
        child: DayRollover(child: ReminderSync(child: HomeShell())),
      ),
    );
  }
}

/// Keeps the mode content (achievements, facts, recovery timeline,
/// motivations) in the language the widget tree resolved.
///
/// The UI strings follow `Localizations` on their own; the content lives in
/// the view models, which sit above this subtree and have to be told. main()
/// sets the starting language, so this only handles later changes — the
/// notification it triggers would land mid-build otherwise.
class _ContentLanguage extends StatefulWidget {
  const _ContentLanguage({required this.child});

  final Widget child;

  @override
  State<_ContentLanguage> createState() => _ContentLanguageState();
}

class _ContentLanguageState extends State<_ContentLanguage> {
  String? _applied;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final strings = ContentStrings.of(Localizations.localeOf(context));
    if (strings.languageCode == _applied) return;
    final first = _applied == null;
    _applied = strings.languageCode;
    if (first) return; // main() already built the view models in this language

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TrackerViewModel>().setContentStrings(strings);
      context.read<ModeViewModel>().setContentStrings(strings);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Keeps "today" current while the app stays in memory.
///
/// Everything that depends on the date — the streak, the "log today" card,
/// the ringed day, where the future starts — is computed when data changes,
/// and Android may keep the app alive for days. So the tracker is told to
/// check the date whenever the app comes back to the foreground, and at the
/// next day boundary (midnight or 04:00, whichever comes first) while it is
/// on screen.
class DayRollover extends StatefulWidget {
  const DayRollover({super.key, required this.child});

  final Widget child;

  @override
  State<DayRollover> createState() => _DayRolloverState();
}

class _DayRolloverState extends State<DayRollover> with WidgetsBindingObserver {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleNextBoundary();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    } else if (state == AppLifecycleState.paused) {
      // Nothing to keep current while nobody is looking; resuming checks.
      _timer?.cancel();
      _timer = null;
    }
  }

  void _refresh() {
    if (!mounted) return;
    context.read<TrackerViewModel>().refreshDay();
    _scheduleNextBoundary();
  }

  void _scheduleNextBoundary() {
    _timer?.cancel();
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final dayStart = DateTime(
      now.year,
      now.month,
      now.day,
      DateOnly.dayStartHour,
    );
    final next = dayStart.isAfter(now) ? dayStart : midnight;
    // A second late, so the clock is unambiguously on the new side.
    _timer = Timer(next.difference(now) + const Duration(seconds: 1), _refresh);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
