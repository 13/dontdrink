import 'dart:async' show unawaited;
import 'dart:io' show Platform;
import 'dart:ui' show PlatformDispatcher;

import 'package:dont_drink/app.dart';
import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/core/theme/font_config.dart';
import 'package:dont_drink/data/repositories/entry_repository.dart';
import 'package:dont_drink/data/repositories/mode_repository.dart';
import 'package:dont_drink/data/repositories/settings_repository.dart';
import 'package:dont_drink/l10n/app_localizations.dart';
import 'package:dont_drink/l10n/content/content_strings.dart';
import 'package:dont_drink/l10n/supported_locales.dart';
import 'package:dont_drink/services/notification_service.dart';
import 'package:dont_drink/viewmodels/mode_viewmodel.dart';
import 'package:dont_drink/viewmodels/settings_viewmodel.dart';
import 'package:dont_drink/viewmodels/tracker_viewmodel.dart';
import 'package:dont_drink/viewmodels/update_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inter is bundled in assets/fonts/, so google_fonts must never reach out to
  // fonts.gstatic.com. Without this the INTERNET permission the updater needs
  // would silently enable a second network destination, contradicting what the
  // About card tells the user.
  configureBundledFonts();

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

    // Settings first, because the stored language decides which language the
    // tracker's content is built in. This used to run alongside the tracker's
    // own load and set the language afterwards, which left everything derived
    // from the mode — the badge list among it — built in English.
    await settingsViewModel.load();

    final startupStrings = ContentStrings.of(
      settingsViewModel.locale ?? _systemLocale(),
    );
    trackerViewModel.setContentStrings(startupStrings);

    // Then the history, before the first frame, so the UI starts in its real
    // state rather than flashing empty values.
    await trackerViewModel.load();

    final modeViewModel = ModeViewModel(
      repository: modeRepository,
      entries: entryRepository,
      onActiveModeChanged: trackerViewModel.switchMode,
    )..setContentStrings(startupStrings);
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

    // The updater is Android-only: this app is distributed as a sideloaded
    // APK, and an iOS build cannot install one, nor does it expose any
    // Settings control that could ever clear a badge the check might set.
    if (Platform.isAndroid) {
      // Once-a-day check for a newer release, after the first frame.
      // Deliberately not awaited and deliberately silent: it must never delay
      // startup or interrupt someone opening the app to log a day.
      unawaited(updateViewModel.silentCheck());

      // Sweep any APK left behind by a previous update's install hand-off.
      // Also not awaited and best-effort: cleanup must never delay startup or
      // surface an error.
      unawaited(updateViewModel.cleanUpDownloadedApks());
    }
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

/// The device language, narrowed to one the app ships. Matches how
/// MaterialApp resolves `supportedLocales` when no explicit locale is set.
Locale _systemLocale() {
  final device = PlatformDispatcher.instance.locale;
  return kSupportedLocales.firstWhere(
    (l) => l.languageCode == device.languageCode,
    orElse: () => kSupportedLocales.first,
  );
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
      supportedLocales: kSupportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        l10n.startupFailedTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.startupFailedBody,
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
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
