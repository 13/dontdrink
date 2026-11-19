import 'package:dont_drink/core/utils/date_utils.dart';
import 'package:dont_drink/l10n/app_localizations.dart';
import 'package:dont_drink/services/notification_service.dart';
import 'package:dont_drink/viewmodels/mode_viewmodel.dart';
import 'package:dont_drink/viewmodels/settings_viewmodel.dart';
import 'package:dont_drink/viewmodels/tracker_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The daily reminder's wording in [l10n]'s language.
ReminderCopy reminderCopyOf(AppLocalizations l10n) => ReminderCopy(
  title: l10n.appTitle,
  body: l10n.notificationBody,
  channelName: l10n.notificationChannelName,
  channelDescription: l10n.notificationChannelDescription,
);

/// Keeps the daily reminder quiet on a day that is already logged.
///
/// Whenever the data or the day changes, it checks whether today is logged
/// in every enabled mode and tells [SettingsViewModel], which re-schedules
/// the reminder to start tomorrow, or back to today when an entry is
/// cleared. It sits below MaterialApp because the reminder's wording comes
/// from [AppLocalizations].
class ReminderSync extends StatefulWidget {
  const ReminderSync({super.key, required this.child});

  final Widget child;

  @override
  State<ReminderSync> createState() => _ReminderSyncState();
}

class _ReminderSyncState extends State<ReminderSync> {
  late final TrackerViewModel _tracker;
  late final ModeViewModel _modes;
  late final SettingsViewModel _settings;

  /// Checks run one at a time; a change during a check asks for another.
  bool _running = false;
  bool _again = false;

  @override
  void initState() {
    super.initState();
    _tracker = context.read<TrackerViewModel>()..addListener(_sync);
    _modes = context.read<ModeViewModel>()..addListener(_sync);
    // Settings too: turning the reminder on has to pick up a day that was
    // logged while it was off.
    _settings = context.read<SettingsViewModel>()..addListener(_sync);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    _tracker.removeListener(_sync);
    _modes.removeListener(_sync);
    _settings.removeListener(_sync);
    super.dispose();
  }

  Future<void> _sync() async {
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    try {
      do {
        _again = false;
        if (!mounted) return;
        final settings = _settings;
        if (!settings.notificationsEnabled) continue;
        final copy = reminderCopyOf(AppLocalizations.of(context));
        // The calendar day: the reminder fires at a clock time, and in the
        // evening the calendar day and the tracked day are the same one.
        final today = DateOnly.today();
        final logged = await _modes.allEnabledLoggedOn(today);
        await settings.setReminderSkipDay(logged ? today : null, copy: copy);
      } while (_again);
    } catch (e) {
      // Best effort, like the reminder itself: the worst case is one
      // reminder on a day that did not need it.
      debugPrint('Reminder sync failed: $e');
    } finally {
      _running = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
