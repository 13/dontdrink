import 'package:dont_drink/app.dart';
import 'package:dont_drink/data/repositories/entry_repository.dart';
import 'package:dont_drink/data/repositories/settings_repository.dart';
import 'package:dont_drink/services/notification_service.dart';
import 'package:dont_drink/viewmodels/settings_viewmodel.dart';
import 'package:dont_drink/viewmodels/tracker_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Notifications init is best-effort; the app works fully without them.
  await NotificationService.instance.init();

  final trackerViewModel = TrackerViewModel(repository: EntryRepository());
  final settingsViewModel =
      SettingsViewModel(repository: SettingsRepository());

  // Load persisted data before the first frame so the UI starts in its real
  // state rather than flashing empty values.
  await Future.wait([
    trackerViewModel.load(),
    settingsViewModel.load(),
  ]);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: trackerViewModel),
        ChangeNotifierProvider.value(value: settingsViewModel),
      ],
      child: const DontDrinkApp(),
    ),
  );
}
