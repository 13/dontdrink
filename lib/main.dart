import 'dart:async' show unawaited;

import 'package:dont_drink/app.dart';
import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/data/repositories/entry_repository.dart';
import 'package:dont_drink/data/repositories/mode_repository.dart';
import 'package:dont_drink/data/repositories/settings_repository.dart';
import 'package:dont_drink/services/notification_service.dart';
import 'package:dont_drink/viewmodels/mode_viewmodel.dart';
import 'package:dont_drink/viewmodels/settings_viewmodel.dart';
import 'package:dont_drink/viewmodels/tracker_viewmodel.dart';
import 'package:dont_drink/viewmodels/update_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Notifications init is best-effort; the app works fully without them, so
  // a failure here (e.g. tz.initializeTimeZones() or the plugin's
  // initialize() throwing) is swallowed rather than allowed to take down
  // startup the way an unguarded throw did before this try/catch existed.
  try {
    await NotificationService.instance.init();
  } catch (e, stack) {
    debugPrint('Notification init failed (continuing without it): $e\n$stack');
  }

  final entryRepository = EntryRepository();
  final modeRepository = ModeRepository(entries: entryRepository);

  try {
    // The tracker is scoped to one mode, so the active mode has to be
    // resolved before it can be built. This is also the first database
    // touch, so a v1→v2 migration (rebuilding the entries table) can run
    // here and fail on a full disk or a corrupt file.
    final ModeDefinition activeMode = await modeRepository.resolveActiveMode();
    final trackerViewModel =
        TrackerViewModel(repository: entryRepository, mode: activeMode);
    final settingsRepository = SettingsRepository();
    final settingsViewModel =
        SettingsViewModel(repository: settingsRepository);

    // Load persisted data before the first frame so the UI starts in its
    // real state rather than flashing empty values.
    await Future.wait([
      trackerViewModel.load(),
      settingsViewModel.load(),
    ]);

    final modeViewModel = ModeViewModel(
      repository: modeRepository,
      entries: entryRepository,
      onActiveModeChanged: trackerViewModel.switchMode,
    );
    await modeViewModel.load();
    trackerViewModel.onDataChanged = modeViewModel.refreshStreaks;

    final updateViewModel = UpdateViewModel(
      settings: settingsRepository,
      currentVersion: () async =>
          (await PackageInfo.fromPlatform()).version,
    );

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: trackerViewModel),
          ChangeNotifierProvider.value(value: settingsViewModel),
          ChangeNotifierProvider.value(value: modeViewModel),
          ChangeNotifierProvider.value(value: updateViewModel),
        ],
        child: const DontDrinkApp(),
      ),
    );

    // Once-a-day check for a newer release, after the first frame. Deliberately
    // not awaited and deliberately silent: it must never delay startup or
    // interrupt someone opening the app to log a day.
    unawaited(updateViewModel.silentCheck());
  } catch (e, stack) {
    // Startup failed before any provider could be built — most likely the
    // v1→v2 migration hitting a full disk or a corrupt database file. The
    // user's data is untouched (the failed transaction rolled back), just
    // unreachable until whatever caused this is fixed, so show enough detail
    // that they can report it rather than staring at a blank screen. Do not
    // attempt automatic recovery or touch the database here.
    debugPrint('Startup failed: $e\n$stack');
    runApp(_StartupErrorApp(error: e));
  }
}

/// Minimal, self-contained error screen shown when startup fails before the
/// real app's providers can be built. Deliberately has no dependency on
/// anything that might itself have failed (theme, providers, repositories).
class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    "Don't Drink couldn't start",
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your data is safe and has not been changed. Please '
                    'report this error.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$error',
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
