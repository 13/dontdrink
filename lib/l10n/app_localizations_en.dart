// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Don\'t Drink';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navAwards => 'Awards';

  @override
  String get navStats => 'Stats';

  @override
  String get navSettings => 'Settings';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonSave => 'Save';

  @override
  String get commonRename => 'Rename';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonLater => 'Later';

  @override
  String get commonImport => 'Import';

  @override
  String get commonInstall => 'Install';

  @override
  String get commonDownload => 'Download';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String dayUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$_temp0';
  }

  @override
  String get dashboardNextAchievement => 'Next Achievement';

  @override
  String get dashboardLogToday => 'Log today';

  @override
  String get dashboardHowDidTodayGo => 'How did today go?';

  @override
  String get streakCurrent => '🔥 Current Streak';

  @override
  String get streakStart => 'Start your streak';

  @override
  String streakOf(String label) {
    return '$label streak';
  }

  @override
  String get streakBest => 'best';

  @override
  String get statCurrentStreak => 'Current streak';

  @override
  String get statLongestStreak => 'Longest streak';

  @override
  String get statTotalCleanDays => 'Total clean days';

  @override
  String get monthNoDaysLogged => 'No days logged this month yet.';

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String get tabBadges => 'Badges';

  @override
  String get tabRecovery => 'Recovery';

  @override
  String badgesUnlockedOf(int unlocked, int total) {
    return '$unlocked of $total unlocked';
  }

  @override
  String badgesEarnedTotal(int count) {
    return '$count earned in total';
  }

  @override
  String badgeTimesChip(int count) {
    return '×$count';
  }

  @override
  String badgeDayThreshold(int day) {
    return 'Day $day';
  }

  @override
  String badgeEarnedOn(String date) {
    return 'Earned $date';
  }

  @override
  String badgeFirstAndLast(String first, String last) {
    return 'First $first · last $last';
  }

  @override
  String badgeEarnedBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Earned $count times before',
      one: 'Earned once before',
    );
    return '$_temp0';
  }

  @override
  String badgeDaysToEarn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more days to earn it',
      one: '1 more day to earn it',
    );
    return '$_temp0';
  }

  @override
  String badgeDaysToEarnAgain(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more days to earn it again',
      one: '1 more day to earn it again',
    );
    return '$_temp0';
  }

  @override
  String get badgeEarnedExclamation => 'Earned!';

  @override
  String get recoveryNoTimelineForMode =>
      'Custom modes don\'t have a recovery timeline.';

  @override
  String get unlockTitle => 'Achievement Unlocked!';

  @override
  String get unlockTitleRepeat => 'Earned Again!';

  @override
  String unlockRepeatChip(int count) {
    return '$count× earned';
  }

  @override
  String get unlockKeepGoing => 'Keep going';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String calendarMonthStatistics(String month) {
    return '$month Statistics';
  }

  @override
  String get calendarLogged => 'Logged';

  @override
  String get calendarCleanRate => 'Clean rate';

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdaySun => 'Sun';

  @override
  String get sheetLogThisDay => 'Log this day';

  @override
  String get sheetClearDay => 'Clear this day';

  @override
  String get factsTitle => 'Facts';

  @override
  String get factOfTheDay => 'Fact of the Day';

  @override
  String get factsNoneForMode => 'This mode has no facts yet.';

  @override
  String get factDidYouKnow => '⚠️  Did you know?';

  @override
  String get factGoodNews => '✨  Good news';

  @override
  String get factShowAnother => 'Show another';

  @override
  String get motivationTitle => 'Motivation';

  @override
  String get motivationInspireMe => 'Inspire me';

  @override
  String get recoveryTimelineTitle => 'Recovery Timeline';

  @override
  String recoveryIntro(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'You\'re $count days into recovery. Here\'s what your body is doing.',
      one: 'You\'re 1 day into recovery. Here\'s what your body is doing.',
    );
    return '$_temp0';
  }

  @override
  String get recoveryNoStreak =>
      'Start a streak to begin your recovery journey.';

  @override
  String recoveryMilestonesReached(int reached, int total) {
    return '$reached of $total milestones reached';
  }

  @override
  String get tierBronze => 'Bronze — The Acute Phase';

  @override
  String get tierSilver => 'Silver — The Regeneration Phase';

  @override
  String get tierGold => 'Gold — The Vitality Phase';

  @override
  String get tierDiamond => 'Diamond — Long-Term Protection';

  @override
  String get tierBronzeRange => 'Days 1 to 7';

  @override
  String get tierSilverRange => 'Weeks 2 to Month 3';

  @override
  String get tierGoldRange => 'Month 6 to Year 2';

  @override
  String get tierDiamondRange => 'Year 5 and Beyond';

  @override
  String get moreTitle => 'More';

  @override
  String get moreMotivationSubtitle => 'A boost when you need it';

  @override
  String get moreSettingsSubtitle => 'Modes, theme, reminders & privacy';

  @override
  String get statsTitle => 'Stats';

  @override
  String get statsQuickStats => 'Quick Stats';

  @override
  String get statsThisMonth => 'This Month';

  @override
  String get statsEmpty => 'Log a few days to see your statistics here.';

  @override
  String statsDaysPerMonth(String label) {
    return '$label Days per Month';
  }

  @override
  String get statsDayDistribution => 'Day Distribution';

  @override
  String get statsOverview => 'Overview';

  @override
  String statsDaysValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String statsRateOf(String label) {
    return '$label rate';
  }

  @override
  String get statsTotalDaysLogged => 'Total days logged';

  @override
  String get statsBestMonth => 'Best month';

  @override
  String statsBestMonthValue(String month, int count) {
    return '$month ($count clean)';
  }

  @override
  String get statsNoDataYet => 'No data yet';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsModes => 'Modes';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get settingsThemeSystem => 'System default';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsDailyReminderSection => 'Daily Reminder';

  @override
  String get settingsDailyReminder => 'Daily reminder';

  @override
  String get settingsDailyReminderSubtitle => 'A gentle nudge to log your day';

  @override
  String get settingsReminderTime => 'Reminder time';

  @override
  String get settingsNotificationDenied =>
      'Notification permission was not granted.';

  @override
  String get settingsData => 'Data';

  @override
  String get settingsUpdates => 'Updates';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsExport => 'Export data';

  @override
  String get settingsExportSubtitle => 'Save a backup of all your logs as JSON';

  @override
  String get settingsImport => 'Import data';

  @override
  String get settingsImportSubtitle => 'Restore logs from a backup file';

  @override
  String settingsExportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String settingsImportFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get settingsImportConfirmBody =>
      'Importing a backup will merge its entries with your current data, across all modes. Days already logged will be overwritten with the values from the file. Days not present in the file are left unchanged.\n\nContinue?';

  @override
  String settingsImportedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Imported $count entries',
      one: 'Imported 1 entry',
    );
    return '$_temp0';
  }

  @override
  String settingsImportedSuccess(String base) {
    return '$base successfully.';
  }

  @override
  String settingsImportedSkipped(String base, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count entries were skipped because they could not be read.',
      one: '1 entry was skipped because it could not be read.',
    );
    return '$base. $_temp0';
  }

  @override
  String settingsVersion(String version, String build) {
    return 'Version $version (build $build)';
  }

  @override
  String settingsBuiltOn(String date) {
    return 'Built on $date';
  }

  @override
  String get settingsPrivacyBody =>
      'All your tracking data is stored privately on this device. No account, no cloud sync. The app contacts GitHub only to check for and download updates.';

  @override
  String get modesCreateCustom => 'Create custom mode';

  @override
  String get modesCreateCustomSubtitle =>
      'Track any habit with clean days and slips';

  @override
  String get modesActive => 'Active';

  @override
  String modesDayStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count day streak',
      one: '1 day streak',
    );
    return '$_temp0';
  }

  @override
  String get modesOffDataKept => 'Off — your data is kept';

  @override
  String modesDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get modesDeleteBodyEmpty =>
      'This mode has no logged days. It will be removed permanently.';

  @override
  String modesDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'This will permanently delete this mode and its $count logged days. This cannot be undone.',
      one:
          'This will permanently delete this mode and its 1 logged day. This cannot be undone.',
    );
    return '$_temp0';
  }

  @override
  String modesDeleteFailed(String error) {
    return 'Could not delete this mode: $error';
  }

  @override
  String get modesSwitchMode => 'Switch mode';

  @override
  String get modesManage => 'Manage modes…';

  @override
  String modesStreakShort(int count) {
    return '$count d';
  }

  @override
  String get modeEditorNew => 'New mode';

  @override
  String get modeEditorRename => 'Rename mode';

  @override
  String get modeEditorSubtitle =>
      'Custom modes track clean days, slips and relapses.';

  @override
  String get modeEditorName => 'Name';

  @override
  String get modeEditorNameHint => 'e.g. No Sugar';

  @override
  String get modeEditorIcon => 'Icon';

  @override
  String get modeEditorCreate => 'Create mode';

  @override
  String modeEditorSaveFailed(String error) {
    return 'Could not save this mode: $error';
  }

  @override
  String get updateCheck => 'Check for updates';

  @override
  String get updateCheckSubtitle => 'Looks for a newer release on GitHub';

  @override
  String get updateChecking => 'Checking for updates…';

  @override
  String get updateUpToDate => 'You\'re up to date';

  @override
  String updateUpToDateSubtitle(String version) {
    return 'Version $version is the latest release';
  }

  @override
  String get updateCheckAgain => 'Check again';

  @override
  String updateAvailable(String version) {
    return 'Version $version is available';
  }

  @override
  String updateDownloadSize(String size) {
    return '$size download';
  }

  @override
  String get updateTapToInstall => 'Tap to download and install';

  @override
  String updateDownloadingVersion(String version) {
    return 'Downloading $version…';
  }

  @override
  String get updateDownloading => 'Downloading…';

  @override
  String updateReady(String version) {
    return 'Version $version is ready';
  }

  @override
  String get updateReadySubtitle =>
      'Android will ask you to confirm the installation';

  @override
  String get updateCheckFailed => 'Couldn\'t check for updates';

  @override
  String get updateDownloadFailed => 'Download failed';

  @override
  String get updateInstallFailed => 'Couldn\'t start the installer';

  @override
  String get notificationChannelName => 'Daily Reminder';

  @override
  String get notificationChannelDescription =>
      'A gentle nudge to log your day.';

  @override
  String get notificationBody => 'How did today go? Tap to log your day.';

  @override
  String get backupShareSubject => 'Don\'t Drink — data backup';

  @override
  String get importErrorNotABackup =>
      'This file doesn\'t look like a Don\'t Drink backup.';

  @override
  String get importErrorMissingEntries =>
      'Backup file is missing the entries list.';

  @override
  String importErrorPartial(int count, String error) {
    return 'Import failed after $count entries: $error';
  }

  @override
  String get importErrorUnreadable => 'Could not read the selected file.';

  @override
  String importErrorReadFailed(String error) {
    return 'Failed to read file: $error';
  }

  @override
  String get importErrorInvalidJson => 'The selected file is not valid JSON.';

  @override
  String get startupFailedTitle => 'Don\'t Drink couldn\'t start';

  @override
  String get startupFailedBody =>
      'Your data is safe and has not been changed. Please report this error.';
}
