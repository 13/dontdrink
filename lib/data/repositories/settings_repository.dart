import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists lightweight user preferences (theme, notifications) in
/// [SharedPreferences]. No personal data, no account.
class SettingsRepository {
  static const _kThemeMode = 'theme_mode';
  static const _kNotifEnabled = 'notif_enabled';
  static const _kNotifHour = 'notif_hour';
  static const _kNotifMinute = 'notif_minute';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<ThemeMode> getThemeMode() async {
    final prefs = await _p;
    final value = prefs.getString(_kThemeMode);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await _p;
    await prefs.setString(_kThemeMode, mode.name);
  }

  Future<bool> getNotificationsEnabled() async {
    final prefs = await _p;
    return prefs.getBool(_kNotifEnabled) ?? false;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await _p;
    await prefs.setBool(_kNotifEnabled, enabled);
  }

  /// Reminder time of day. Defaults to 20:00 (8:00 PM) per the spec.
  Future<TimeOfDay> getReminderTime() async {
    final prefs = await _p;
    final hour = prefs.getInt(_kNotifHour) ?? 20;
    final minute = prefs.getInt(_kNotifMinute) ?? 0;
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    final prefs = await _p;
    await prefs.setInt(_kNotifHour, time.hour);
    await prefs.setInt(_kNotifMinute, time.minute);
  }
}
