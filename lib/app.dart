import 'package:dont_drink/core/theme/app_theme.dart';
import 'package:dont_drink/l10n/app_localizations.dart';
import 'package:dont_drink/l10n/supported_locales.dart';
import 'package:dont_drink/ui/shell/home_shell.dart';
import 'package:dont_drink/viewmodels/settings_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

class DontDrinkApp extends StatelessWidget {
  const DontDrinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode =
        context.select<SettingsViewModel, ThemeMode>((vm) => vm.themeMode);
    // null means "follow the system": MaterialApp then resolves the device
    // locale against supportedLocales and falls back to English.
    final locale = context.select<SettingsViewModel, Locale?>((vm) => vm.locale);

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
      home: const HomeShell(),
    );
  }
}
