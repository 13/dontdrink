import 'package:dont_drink/l10n/supported_locales.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists lightweight user preferences (theme, notifications, updater
/// state) in [SharedPreferences]. No personal data, no account.
class SettingsRepository {
  static const _kThemeMode = 'theme_mode';
  static const _kLocale = 'locale';
  static const _kNotifEnabled = 'notif_enabled';
  static const _kNotifHour = 'notif_hour';
  static const _kNotifMinute = 'notif_minute';
  static const _kLastUpdateCheck = 'last_update_check';
  static const _kSkippedVersion = 'skipped_version';

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

  /// The language the user picked, or null for "follow the system".
  ///
  /// Stored as a language code ('de', 'it', 'en'); anything unrecognized is
  /// treated as "follow the system" so a stale value can never strand the UI
  /// in a language the app no longer ships.
  Future<Locale?> getLocale() async {
    final prefs = await _p;
    final code = prefs.getString(_kLocale);
    if (code == null) return null;
    return kSupportedLocales
        .where((l) => l.languageCode == code)
        .firstOrNull;
  }

  /// Pass null to follow the system language.
  Future<void> setLocale(Locale? locale) async {
    final prefs = await _p;
    if (locale == null) {
      await prefs.remove(_kLocale);
    } else {
      await prefs.setString(_kLocale, locale.languageCode);
    }
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

  // ── Updater ──────────────────────────────────────────────────────────────

  /// When the app last asked GitHub for a release, or null if never.
  /// Drives the once-per-24h throttle on the silent launch check.
  Future<DateTime?> getLastUpdateCheck() async {
    final prefs = await _p;
    final millis = prefs.getInt(_kLastUpdateCheck);
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> setLastUpdateCheck(DateTime when) async {
    final prefs = await _p;
    await prefs.setInt(_kLastUpdateCheck, when.millisecondsSinceEpoch);
  }

  /// A version the user dismissed with "Later". Silent checks stay quiet for
  /// this version but still surface anything newer.
  Future<String?> getSkippedVersion() async {
    final prefs = await _p;
    return prefs.getString(_kSkippedVersion);
  }

  Future<void> setSkippedVersion(String version) async {
    final prefs = await _p;
    await prefs.setString(_kSkippedVersion, version);
  }

  Future<void> clearSkippedVersion() async {
    final prefs = await _p;
    await prefs.remove(_kSkippedVersion);
  }
}
