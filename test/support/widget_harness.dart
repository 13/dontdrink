import 'dart:io';

import 'package:flutter/foundation.dart' show ValueListenable;

import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/data/database/app_database.dart';
import 'package:dont_drink/data/repositories/entry_repository.dart';
import 'package:dont_drink/data/repositories/mode_repository.dart';
import 'package:dont_drink/data/static/modes/mode_registry.dart';
import 'package:dont_drink/l10n/app_localizations.dart';
import 'package:dont_drink/l10n/supported_locales.dart';
import 'package:dont_drink/viewmodels/mode_viewmodel.dart';
import 'package:dont_drink/viewmodels/tracker_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Test scaffolding for the widget tests.
///
/// Screens here need three things the default `pumpWidget` does not give
/// them: the provider tree, the localization delegates (every widget reads
/// `AppLocalizations.of`), and a real SQLite database, because the view models
/// talk to repositories rather than mocks. `sqflite_common_ffi` supplies the
/// last one on the host, exactly as the repository tests already do.
class WidgetHarness {
  WidgetHarness._(this.tempDir, this.entries, this.tracker, this.modes);

  final Directory tempDir;
  final EntryRepository entries;
  final TrackerViewModel tracker;
  final ModeViewModel modes;

  /// Call once per test file, before any harness is created.
  ///
  /// The *no-isolate* factory matters: `testWidgets` runs its body in a
  /// fake-async zone, and work handed to a real isolate never completes there.
  /// With the ordinary ffi factory a tap that writes to the database hangs
  /// forever — the save never returns, so nothing that follows it ever runs.
  static void initDatabase() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  }

  static Future<WidgetHarness> create({
    ModeDefinition? mode,
  }) async {
    // ModeRepository reads the enabled/active selection from
    // SharedPreferences, which has no implementation on the host.
    SharedPreferences.setMockInitialValues({});

    final active = mode ?? kDefaultMode;
    final dir = Directory.systemTemp.createTempSync('dontdrink_widget_test');
    // AppDatabase is a singleton and caches its connection. Without closing
    // it, the next test opens a new temp directory while the old, now-deleted
    // file is still attached, and SQLite reports the database as read-only.
    await AppDatabase.instance.close();
    await databaseFactory.setDatabasesPath(dir.path);

    final entryRepository = EntryRepository();
    for (final m in kBuiltInModes) {
      await entryRepository.deleteAllForMode(m.id);
    }

    final tracker =
        TrackerViewModel(repository: entryRepository, mode: active);
    await tracker.load();

    final modeViewModel = ModeViewModel(
      repository: ModeRepository(entries: entryRepository),
      entries: entryRepository,
      onActiveModeChanged: tracker.switchMode,
    );
    await modeViewModel.load();

    return WidgetHarness._(dir, entryRepository, tracker, modeViewModel);
  }

  Future<void> dispose() async {
    await AppDatabase.instance.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  }

  /// Wrap [child] in everything a screen of this app expects to find above it.
  ///
  /// [locale] forces a language; leave it null for the English default.
  ///
  /// [keyboardInset] publishes a bottom `viewInsets` value — a stand-in for
  /// the on-screen keyboard, which a widget test otherwise never has. It is
  /// applied in `MaterialApp.builder`, *above* the Navigator, because that is
  /// the only place routes pushed later (dialogs, bottom sheets) inherit from;
  /// a MediaQuery inside `home` reaches the home screen and nothing else.
  Widget wrap(
    Widget child, {
    Locale? locale,
    ValueListenable<double>? keyboardInset,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: tracker),
        ChangeNotifierProvider.value(value: modes),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: kSupportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: keyboardInset == null
            ? null
            : (context, navigator) => ValueListenableBuilder<double>(
                  valueListenable: keyboardInset,
                  builder: (context, bottom, _) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(viewInsets: EdgeInsets.only(bottom: bottom)),
                    child: navigator!,
                  ),
                ),
        home: child,
      ),
    );
  }
}
