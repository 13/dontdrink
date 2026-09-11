import 'package:dont_drink/data/repositories/settings_repository.dart';
import 'package:dont_drink/services/notification_service.dart';
import 'package:flutter/material.dart';

/// View model for app settings: theme mode, language, and the optional daily
/// reminder.
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

  /// The language the user picked, or null while following the system.
  Locale? _locale;
  Locale? get locale => _locale;

  bool _notificationsEnabled = false;
  bool get notificationsEnabled => _notificationsEnabled;

  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  TimeOfDay get reminderTime => _reminderTime;

  Future<void> load() async {
    _themeMode = await _repo.getThemeMode();
    _locale = await _repo.getLocale();
    _notificationsEnabled = await _repo.getNotificationsEnabled();
    _reminderTime = await _repo.getReminderTime();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _repo.setThemeMode(mode);
  }

  /// Set the app language, or pass null to follow the system again.
  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    notifyListeners();
    await _repo.setLocale(locale);
  }

  /// Toggle the daily reminder. Requests OS permission when enabling; if the
  /// user declines we keep it off. Returns true if the final state is enabled.
  Future<bool> setNotificationsEnabled(
    bool enabled, {
    required ReminderCopy copy,
  }) async {
    if (enabled) {
      final granted = await _notifications.requestPermissions();
      if (!granted) {
        _notificationsEnabled = false;
        notifyListeners();
        return false;
      }
      await _notifications.scheduleDailyReminder(_reminderTime, copy: copy);
    } else {
      await _notifications.cancelDailyReminder();
    }
    _notificationsEnabled = enabled;
    notifyListeners();
    await _repo.setNotificationsEnabled(enabled);
    return enabled;
  }

  Future<void> setReminderTime(
    TimeOfDay time, {
    required ReminderCopy copy,
  }) async {
    _reminderTime = time;
    notifyListeners();
    await _repo.setReminderTime(time);
    if (_notificationsEnabled) {
      await _notifications.scheduleDailyReminder(time, copy: copy);
    }
  }

  /// Re-schedule the reminder so its wording follows a language change.
  /// Does nothing when the reminder is off.
  Future<void> refreshReminderCopy(ReminderCopy copy) async {
    if (!_notificationsEnabled) return;
    await _notifications.scheduleDailyReminder(_reminderTime, copy: copy);
  }
}
