import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// The translated wording of the daily reminder, handed to
/// [NotificationService.scheduleDailyReminder] by the UI layer, which is where
/// `AppLocalizations` is reachable.
class ReminderCopy {
  const ReminderCopy({
    required this.title,
    required this.body,
    required this.channelName,
    required this.channelDescription,
  });

  final String title;
  final String body;
  final String channelName;
  final String channelDescription;
}

/// Wraps [FlutterLocalNotificationsPlugin] to schedule the optional daily
/// "How did today go?" reminder. All scheduling is on-device.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _dailyReminderId = 1001;
  static const String _channelId = 'daily_reminder';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    _initialized = true;
  }

  /// Ask the OS for permission to post notifications. Returns true if granted
  /// (or already granted).
  Future<bool> requestPermissions() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted = await android?.requestNotificationsPermission();

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );

    // If neither platform implementation responded, assume granted (e.g. tests).
    return androidGranted ?? iosGranted ?? true;
  }

  /// Schedule a repeating daily reminder at [time]. Replaces any existing one.
  ///
  /// The wording is passed in rather than held here: a notification is built
  /// outside the widget tree, so this service has no access to
  /// `AppLocalizations` and would otherwise be the one English corner left in
  /// a translated app.
  Future<void> scheduleDailyReminder(
    TimeOfDay time, {
    required ReminderCopy copy,
  }) async {
    await init();
    await cancelDailyReminder();

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        copy.channelName,
        channelDescription: copy.channelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    // One reminder for the whole app, not one per active mode: several active
    // modes should not mean several nightly pings.
    await _plugin.zonedSchedule(
      id: _dailyReminderId,
      title: copy.title,
      body: copy.body,
      scheduledDate: _nextInstanceOf(time),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminder() async {
    await init();
    await _plugin.cancel(id: _dailyReminderId);
  }

  /// The next occurrence of [time] in local time, today if still upcoming.
  tz.TZDateTime _nextInstanceOf(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
