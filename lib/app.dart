import 'package:dont_drink/core/theme/app_theme.dart';
import 'package:dont_drink/ui/shell/home_shell.dart';
import 'package:dont_drink/viewmodels/settings_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DontDrinkApp extends StatelessWidget {
  const DontDrinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode =
        context.select<SettingsViewModel, ThemeMode>((vm) => vm.themeMode);

    return MaterialApp(
      title: "Don't Drink",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: const HomeShell(),
    );
  }
}
