import 'package:dont_drink/data/repositories/settings_repository.dart';
import 'package:dont_drink/services/notification_service.dart';
import 'package:flutter/material.dart';

/// View model for app settings: theme mode and the optional daily reminder.
class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({
    required SettingsRepository repository,
    NotificationService? notifications,
  })  : _repo = repository,
        _notifications = notifications ?? NotificationService.instance;

  final SettingsRepository _repo;
  final NotificationService _notifications;

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  bool _notificationsEnabled = false;
  bool get notificationsEnabled => _notificationsEnabled;

  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay get reminderTime => _reminderTime;

  Future<void> load() async {
    _themeMode = await _repo.getThemeMode();
    _notificationsEnabled = await _repo.getNotificationsEnabled();
    _reminderTime = await _repo.getReminderTime();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _repo.setThemeMode(mode);
  }

  /// Toggle the daily reminder. Requests OS permission when enabling; if the
  /// user declines we keep it off. Returns true if the final state is enabled.
  Future<bool> setNotificationsEnabled(bool enabled) async {
    if (enabled) {
      final granted = await _notifications.requestPermissions();
      if (!granted) {
        _notificationsEnabled = false;
        notifyListeners();
        return false;
      }
      await _notifications.scheduleDailyReminder(_reminderTime);
    } else {
      await _notifications.cancelDailyReminder();
    }
    _notificationsEnabled = enabled;
    notifyListeners();
    await _repo.setNotificationsEnabled(enabled);
    return enabled;
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    _reminderTime = time;
    notifyListeners();
    await _repo.setReminderTime(time);
    if (_notificationsEnabled) {
      await _notifications.scheduleDailyReminder(time);
    }
  }
}
