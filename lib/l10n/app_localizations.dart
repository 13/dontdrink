import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('it'),
  ];

  /// App name, shown as the task title
  ///
  /// In en, this message translates to:
  /// **'Don\'t Drink'**
  String get appTitle;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navAwards.
  ///
  /// In en, this message translates to:
  /// **'Awards'**
  String get navAwards;

  /// No description provided for @navStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get navStats;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get commonRename;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get commonLater;

  /// No description provided for @commonImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get commonImport;

  /// No description provided for @commonInstall.
  ///
  /// In en, this message translates to:
  /// **'Install'**
  String get commonInstall;

  /// No description provided for @commonDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get commonDownload;

  /// No description provided for @dayCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String dayCount(int count);

  /// Bare unit shown next to a large streak number
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{day} other{days}}'**
  String dayUnit(int count);

  /// No description provided for @dashboardNextAchievement.
  ///
  /// In en, this message translates to:
  /// **'Next Achievement'**
  String get dashboardNextAchievement;

  /// No description provided for @dashboardLogToday.
  ///
  /// In en, this message translates to:
  /// **'Log today'**
  String get dashboardLogToday;

  /// No description provided for @dashboardHowDidTodayGo.
  ///
  /// In en, this message translates to:
  /// **'How did today go?'**
  String get dashboardHowDidTodayGo;

  /// No description provided for @streakCurrent.
  ///
  /// In en, this message translates to:
  /// **'🔥 Current Streak'**
  String get streakCurrent;

  /// No description provided for @streakStart.
  ///
  /// In en, this message translates to:
  /// **'Start your streak'**
  String get streakStart;

  /// e.g. 'alcohol-free streak'; label comes from the mode
  ///
  /// In en, this message translates to:
  /// **'{label} streak'**
  String streakOf(String label);

  /// No description provided for @streakBest.
  ///
  /// In en, this message translates to:
  /// **'best'**
  String get streakBest;

  /// No description provided for @statCurrentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get statCurrentStreak;

  /// No description provided for @statLongestStreak.
  ///
  /// In en, this message translates to:
  /// **'Longest streak'**
  String get statLongestStreak;

  /// No description provided for @statTotalCleanDays.
  ///
  /// In en, this message translates to:
  /// **'Total clean days'**
  String get statTotalCleanDays;

  /// No description provided for @monthNoDaysLogged.
  ///
  /// In en, this message translates to:
  /// **'No days logged this month yet.'**
  String get monthNoDaysLogged;

  /// No description provided for @achievementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievementsTitle;

  /// No description provided for @tabBadges.
  ///
  /// In en, this message translates to:
  /// **'Badges'**
  String get tabBadges;

  /// No description provided for @tabRecovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get tabRecovery;

  /// No description provided for @badgesUnlockedOf.
  ///
  /// In en, this message translates to:
  /// **'{unlocked} of {total} unlocked'**
  String badgesUnlockedOf(int unlocked, int total);

  /// No description provided for @badgesEarnedTotal.
  ///
  /// In en, this message translates to:
  /// **'{count} earned in total'**
  String badgesEarnedTotal(int count);

  /// No description provided for @badgeTimesChip.
  ///
  /// In en, this message translates to:
  /// **'×{count}'**
  String badgeTimesChip(int count);

  /// No description provided for @badgeDayThreshold.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String badgeDayThreshold(int day);

  /// No description provided for @badgeEarnedOn.
  ///
  /// In en, this message translates to:
  /// **'Earned {date}'**
  String badgeEarnedOn(String date);

  /// No description provided for @badgeFirstAndLast.
  ///
  /// In en, this message translates to:
  /// **'First {first} · last {last}'**
  String badgeFirstAndLast(String first, String last);

  /// No description provided for @badgeEarnedBefore.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Earned once before} other{Earned {count} times before}}'**
  String badgeEarnedBefore(int count);

  /// No description provided for @badgeDaysToEarn.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more day to earn it} other{{count} more days to earn it}}'**
  String badgeDaysToEarn(int count);

  /// No description provided for @badgeDaysToEarnAgain.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 more day to earn it again} other{{count} more days to earn it again}}'**
  String badgeDaysToEarnAgain(int count);

  /// No description provided for @badgeEarnedExclamation.
  ///
  /// In en, this message translates to:
  /// **'Earned!'**
  String get badgeEarnedExclamation;

  /// No description provided for @recoveryNoTimelineForMode.
  ///
  /// In en, this message translates to:
  /// **'Custom modes don\'t have a recovery timeline.'**
  String get recoveryNoTimelineForMode;

  /// No description provided for @unlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievement Unlocked!'**
  String get unlockTitle;

  /// No description provided for @unlockTitleRepeat.
  ///
  /// In en, this message translates to:
  /// **'Earned Again!'**
  String get unlockTitleRepeat;

  /// No description provided for @unlockRepeatChip.
  ///
  /// In en, this message translates to:
  /// **'{count}× earned'**
  String unlockRepeatChip(int count);

  /// No description provided for @unlockKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep going'**
  String get unlockKeepGoing;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendarTitle;

  /// No description provided for @calendarMonthStatistics.
  ///
  /// In en, this message translates to:
  /// **'{month} Statistics'**
  String calendarMonthStatistics(String month);

  /// No description provided for @calendarLogged.
  ///
  /// In en, this message translates to:
  /// **'Logged'**
  String get calendarLogged;

  /// No description provided for @calendarCleanRate.
  ///
  /// In en, this message translates to:
  /// **'Clean rate'**
  String get calendarCleanRate;

  /// No description provided for @weekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weekdaySun;

  /// No description provided for @sheetLogThisDay.
  ///
  /// In en, this message translates to:
  /// **'Log this day'**
  String get sheetLogThisDay;

  /// No description provided for @sheetClearDay.
  ///
  /// In en, this message translates to:
  /// **'Clear this day'**
  String get sheetClearDay;

  /// No description provided for @factsTitle.
  ///
  /// In en, this message translates to:
  /// **'Facts'**
  String get factsTitle;

  /// No description provided for @factOfTheDay.
  ///
  /// In en, this message translates to:
  /// **'Fact of the Day'**
  String get factOfTheDay;

  /// No description provided for @factsNoneForMode.
  ///
  /// In en, this message translates to:
  /// **'This mode has no facts yet.'**
  String get factsNoneForMode;

  /// No description provided for @factDidYouKnow.
  ///
  /// In en, this message translates to:
  /// **'⚠️  Did you know?'**
  String get factDidYouKnow;

  /// No description provided for @factGoodNews.
  ///
  /// In en, this message translates to:
  /// **'✨  Good news'**
  String get factGoodNews;

  /// No description provided for @factShowAnother.
  ///
  /// In en, this message translates to:
  /// **'Show another'**
  String get factShowAnother;

  /// No description provided for @motivationTitle.
  ///
  /// In en, this message translates to:
  /// **'Motivation'**
  String get motivationTitle;

  /// No description provided for @motivationInspireMe.
  ///
  /// In en, this message translates to:
  /// **'Inspire me'**
  String get motivationInspireMe;

  /// No description provided for @recoveryTimelineTitle.
  ///
  /// In en, this message translates to:
  /// **'Recovery Timeline'**
  String get recoveryTimelineTitle;

  /// No description provided for @recoveryIntro.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You\'re 1 day into recovery. Here\'s what your body is doing.} other{You\'re {count} days into recovery. Here\'s what your body is doing.}}'**
  String recoveryIntro(int count);

  /// No description provided for @recoveryNoStreak.
  ///
  /// In en, this message translates to:
  /// **'Start a streak to begin your recovery journey.'**
  String get recoveryNoStreak;

  /// No description provided for @recoveryMilestonesReached.
  ///
  /// In en, this message translates to:
  /// **'{reached} of {total} milestones reached'**
  String recoveryMilestonesReached(int reached, int total);

  /// No description provided for @tierBronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze — The Acute Phase'**
  String get tierBronze;

  /// No description provided for @tierSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver — The Regeneration Phase'**
  String get tierSilver;

  /// No description provided for @tierGold.
  ///
  /// In en, this message translates to:
  /// **'Gold — The Vitality Phase'**
  String get tierGold;

  /// No description provided for @tierDiamond.
  ///
  /// In en, this message translates to:
  /// **'Diamond — Long-Term Protection'**
  String get tierDiamond;

  /// No description provided for @tierBronzeRange.
  ///
  /// In en, this message translates to:
  /// **'Days 1 to 7'**
  String get tierBronzeRange;

  /// No description provided for @tierSilverRange.
  ///
  /// In en, this message translates to:
  /// **'Weeks 2 to Month 3'**
  String get tierSilverRange;

  /// No description provided for @tierGoldRange.
  ///
  /// In en, this message translates to:
  /// **'Month 6 to Year 2'**
  String get tierGoldRange;

  /// No description provided for @tierDiamondRange.
  ///
  /// In en, this message translates to:
  /// **'Year 5 and Beyond'**
  String get tierDiamondRange;

  /// No description provided for @moreTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreTitle;

  /// No description provided for @moreMotivationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A boost when you need it'**
  String get moreMotivationSubtitle;

  /// No description provided for @moreSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Modes, theme, reminders & privacy'**
  String get moreSettingsSubtitle;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get statsTitle;

  /// No description provided for @statsQuickStats.
  ///
  /// In en, this message translates to:
  /// **'Quick Stats'**
  String get statsQuickStats;

  /// No description provided for @statsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get statsThisMonth;

  /// No description provided for @statsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Log a few days to see your statistics here.'**
  String get statsEmpty;

  /// No description provided for @statsDaysPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{label} Days per Month'**
  String statsDaysPerMonth(String label);

  /// No description provided for @statsDayDistribution.
  ///
  /// In en, this message translates to:
  /// **'Day Distribution'**
  String get statsDayDistribution;

  /// No description provided for @statsOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get statsOverview;

  /// No description provided for @statsDaysValue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String statsDaysValue(int count);

  /// No description provided for @statsRateOf.
  ///
  /// In en, this message translates to:
  /// **'{label} rate'**
  String statsRateOf(String label);

  /// No description provided for @statsTotalDaysLogged.
  ///
  /// In en, this message translates to:
  /// **'Total days logged'**
  String get statsTotalDaysLogged;

  /// No description provided for @statsBestMonth.
  ///
  /// In en, this message translates to:
  /// **'Best month'**
  String get statsBestMonth;

  /// No description provided for @statsBestMonthValue.
  ///
  /// In en, this message translates to:
  /// **'{month} ({count} clean)'**
  String statsBestMonthValue(String month, int count);

  /// No description provided for @statsNoDataYet.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get statsNoDataYet;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsModes.
  ///
  /// In en, this message translates to:
  /// **'Modes'**
  String get settingsModes;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsDailyReminderSection.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder'**
  String get settingsDailyReminderSection;

  /// No description provided for @settingsDailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get settingsDailyReminder;

  /// No description provided for @settingsDailyReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A gentle nudge to log your day'**
  String get settingsDailyReminderSubtitle;

  /// No description provided for @settingsReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder time'**
  String get settingsReminderTime;

  /// No description provided for @settingsNotificationDenied.
  ///
  /// In en, this message translates to:
  /// **'Notification permission was not granted.'**
  String get settingsNotificationDenied;

  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsData;

  /// No description provided for @settingsUpdates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get settingsUpdates;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsExport.
  ///
  /// In en, this message translates to:
  /// **'Export data'**
  String get settingsExport;

  /// No description provided for @settingsExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save a backup of all your logs as JSON'**
  String get settingsExportSubtitle;

  /// No description provided for @settingsImport.
  ///
  /// In en, this message translates to:
  /// **'Import data'**
  String get settingsImport;

  /// No description provided for @settingsImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restore logs from a backup file'**
  String get settingsImportSubtitle;

  /// No description provided for @settingsExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String settingsExportFailed(String error);

  /// No description provided for @settingsImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String settingsImportFailed(String error);

  /// No description provided for @settingsImportConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Importing a backup will merge its entries with your current data, across all modes. Days already logged will be overwritten with the values from the file. Days not present in the file are left unchanged.\n\nContinue?'**
  String get settingsImportConfirmBody;

  /// No description provided for @settingsImportedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Imported 1 entry} other{Imported {count} entries}}'**
  String settingsImportedCount(int count);

  /// No description provided for @settingsImportedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{base} successfully.'**
  String settingsImportedSuccess(String base);

  /// No description provided for @settingsImportedSkipped.
  ///
  /// In en, this message translates to:
  /// **'{base}. {count, plural, =1{1 entry was skipped because it could not be read.} other{{count} entries were skipped because they could not be read.}}'**
  String settingsImportedSkipped(String base, int count);

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version} (build {build})'**
  String settingsVersion(String version, String build);

  /// No description provided for @settingsBuiltOn.
  ///
  /// In en, this message translates to:
  /// **'Built on {date}'**
  String settingsBuiltOn(String date);

  /// No description provided for @settingsPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'All your tracking data is stored privately on this device. No account, no cloud sync. The app contacts GitHub only to check for and download updates.'**
  String get settingsPrivacyBody;

  /// No description provided for @modesCreateCustom.
  ///
  /// In en, this message translates to:
  /// **'Create custom mode'**
  String get modesCreateCustom;

  /// No description provided for @modesCreateCustomSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Track any habit with clean days and slips'**
  String get modesCreateCustomSubtitle;

  /// No description provided for @modesActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get modesActive;

  /// No description provided for @modesDayStreak.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day streak} other{{count} day streak}}'**
  String modesDayStreak(int count);

  /// No description provided for @modesOffDataKept.
  ///
  /// In en, this message translates to:
  /// **'Off — your data is kept'**
  String get modesOffDataKept;

  /// No description provided for @modesDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String modesDeleteTitle(String name);

  /// No description provided for @modesDeleteBodyEmpty.
  ///
  /// In en, this message translates to:
  /// **'This mode has no logged days. It will be removed permanently.'**
  String get modesDeleteBodyEmpty;

  /// No description provided for @modesDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{This will permanently delete this mode and its 1 logged day. This cannot be undone.} other{This will permanently delete this mode and its {count} logged days. This cannot be undone.}}'**
  String modesDeleteBody(int count);

  /// No description provided for @modesDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete this mode: {error}'**
  String modesDeleteFailed(String error);

  /// No description provided for @modesSwitchMode.
  ///
  /// In en, this message translates to:
  /// **'Switch mode'**
  String get modesSwitchMode;

  /// No description provided for @modesManage.
  ///
  /// In en, this message translates to:
  /// **'Manage modes…'**
  String get modesManage;

  /// Compact streak badge in the mode switcher
  ///
  /// In en, this message translates to:
  /// **'{count} d'**
  String modesStreakShort(int count);

  /// No description provided for @modeEditorNew.
  ///
  /// In en, this message translates to:
  /// **'New mode'**
  String get modeEditorNew;

  /// No description provided for @modeEditorRename.
  ///
  /// In en, this message translates to:
  /// **'Rename mode'**
  String get modeEditorRename;

  /// No description provided for @modeEditorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Custom modes track clean days, slips and relapses.'**
  String get modeEditorSubtitle;

  /// No description provided for @modeEditorName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get modeEditorName;

  /// No description provided for @modeEditorNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. No Sugar'**
  String get modeEditorNameHint;

  /// No description provided for @modeEditorIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get modeEditorIcon;

  /// No description provided for @modeEditorCreate.
  ///
  /// In en, this message translates to:
  /// **'Create mode'**
  String get modeEditorCreate;

  /// No description provided for @modeEditorSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save this mode: {error}'**
  String modeEditorSaveFailed(String error);

  /// No description provided for @updateCheck.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get updateCheck;

  /// No description provided for @updateCheckSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Looks for a newer release on GitHub'**
  String get updateCheckSubtitle;

  /// No description provided for @updateChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates…'**
  String get updateChecking;

  /// No description provided for @updateUpToDate.
  ///
  /// In en, this message translates to:
  /// **'You\'re up to date'**
  String get updateUpToDate;

  /// No description provided for @updateUpToDateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is the latest release'**
  String updateUpToDateSubtitle(String version);

  /// No description provided for @updateCheckAgain.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get updateCheckAgain;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is available'**
  String updateAvailable(String version);

  /// No description provided for @updateDownloadSize.
  ///
  /// In en, this message translates to:
  /// **'{size} download'**
  String updateDownloadSize(String size);

  /// No description provided for @updateTapToInstall.
  ///
  /// In en, this message translates to:
  /// **'Tap to download and install'**
  String get updateTapToInstall;

  /// No description provided for @updateDownloadingVersion.
  ///
  /// In en, this message translates to:
  /// **'Downloading {version}…'**
  String updateDownloadingVersion(String version);

  /// No description provided for @updateDownloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading…'**
  String get updateDownloading;

  /// No description provided for @updateReady.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is ready'**
  String updateReady(String version);

  /// No description provided for @updateReadySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Android will ask you to confirm the installation'**
  String get updateReadySubtitle;

  /// No description provided for @updateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check for updates'**
  String get updateCheckFailed;

  /// No description provided for @updateDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get updateDownloadFailed;

  /// No description provided for @updateInstallFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start the installer'**
  String get updateInstallFailed;

  /// No description provided for @notificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder'**
  String get notificationChannelName;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'A gentle nudge to log your day.'**
  String get notificationChannelDescription;

  /// No description provided for @notificationBody.
  ///
  /// In en, this message translates to:
  /// **'How did today go? Tap to log your day.'**
  String get notificationBody;

  /// No description provided for @backupShareSubject.
  ///
  /// In en, this message translates to:
  /// **'Don\'t Drink — data backup'**
  String get backupShareSubject;

  /// No description provided for @importErrorNotABackup.
  ///
  /// In en, this message translates to:
  /// **'This file doesn\'t look like a Don\'t Drink backup.'**
  String get importErrorNotABackup;

  /// No description provided for @importErrorMissingEntries.
  ///
  /// In en, this message translates to:
  /// **'Backup file is missing the entries list.'**
  String get importErrorMissingEntries;

  /// No description provided for @importErrorPartial.
  ///
  /// In en, this message translates to:
  /// **'Import failed after {count} entries: {error}'**
  String importErrorPartial(int count, String error);

  /// No description provided for @importErrorUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Could not read the selected file.'**
  String get importErrorUnreadable;

  /// No description provided for @importErrorReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to read file: {error}'**
  String importErrorReadFailed(String error);

  /// No description provided for @importErrorInvalidJson.
  ///
  /// In en, this message translates to:
  /// **'The selected file is not valid JSON.'**
  String get importErrorInvalidJson;

  /// No description provided for @modesRuleSwitchFirst.
  ///
  /// In en, this message translates to:
  /// **'Switch to another mode before turning this one off.'**
  String get modesRuleSwitchFirst;

  /// No description provided for @modesRuleKeepOne.
  ///
  /// In en, this message translates to:
  /// **'At least one mode has to stay on.'**
  String get modesRuleKeepOne;

  /// Quiet acknowledgement headline; count is the current streak
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Day 1 down} other{Day {count} down}}'**
  String cheerTitle(int count);

  /// No description provided for @cheerBody0.
  ///
  /// In en, this message translates to:
  /// **'Logged. That is the whole job today.'**
  String get cheerBody0;

  /// No description provided for @cheerBody1.
  ///
  /// In en, this message translates to:
  /// **'Another one on the board.'**
  String get cheerBody1;

  /// No description provided for @cheerBody2.
  ///
  /// In en, this message translates to:
  /// **'Quietly, this is what progress looks like.'**
  String get cheerBody2;

  /// No description provided for @cheerBody3.
  ///
  /// In en, this message translates to:
  /// **'Showing up counts, even on the ordinary days.'**
  String get cheerBody3;

  /// No description provided for @cheerBody4.
  ///
  /// In en, this message translates to:
  /// **'You kept your word to yourself today.'**
  String get cheerBody4;

  /// No description provided for @cheerClose.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get cheerClose;

  /// No description provided for @comfortTitle.
  ///
  /// In en, this message translates to:
  /// **'Today is logged'**
  String get comfortTitle;

  /// No description provided for @comfortBody0.
  ///
  /// In en, this message translates to:
  /// **'It happened, and you wrote it down anyway. That takes something.'**
  String get comfortBody0;

  /// No description provided for @comfortBody1.
  ///
  /// In en, this message translates to:
  /// **'One day is a data point, not a verdict.'**
  String get comfortBody1;

  /// No description provided for @comfortBody2.
  ///
  /// In en, this message translates to:
  /// **'Being honest with yourself is the part that keeps working.'**
  String get comfortBody2;

  /// No description provided for @comfortBody3.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow is a separate day. It starts clean.'**
  String get comfortBody3;

  /// No description provided for @comfortBody4.
  ///
  /// In en, this message translates to:
  /// **'Nothing about this erases the days you already held.'**
  String get comfortBody4;

  /// Reassurance that earned badges are never taken away
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Your best streak still stands.} =1{Your 1 badge and your best streak are still yours.} other{Your {count} badges and your best streak are still yours.}}'**
  String comfortKept(int count);

  /// No description provided for @comfortBoost.
  ///
  /// In en, this message translates to:
  /// **'Need a boost'**
  String get comfortBoost;

  /// No description provided for @comfortClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get comfortClose;

  /// No description provided for @moreCalendarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The whole month, with a legend and totals'**
  String get moreCalendarSubtitle;

  /// No description provided for @updateErrorNoConnection.
  ///
  /// In en, this message translates to:
  /// **'Could not reach GitHub. Check your connection.'**
  String get updateErrorNoConnection;

  /// No description provided for @updateErrorInsecureConnection.
  ///
  /// In en, this message translates to:
  /// **'Could not establish a secure connection.'**
  String get updateErrorInsecureConnection;

  /// No description provided for @updateErrorConnectionInterrupted.
  ///
  /// In en, this message translates to:
  /// **'The connection was interrupted. Please try again.'**
  String get updateErrorConnectionInterrupted;

  /// No description provided for @updateErrorTimedOut.
  ///
  /// In en, this message translates to:
  /// **'The update check timed out. Please try again.'**
  String get updateErrorTimedOut;

  /// No description provided for @updateErrorNoReleases.
  ///
  /// In en, this message translates to:
  /// **'No releases have been published yet.'**
  String get updateErrorNoReleases;

  /// No description provided for @updateErrorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'GitHub is rate-limiting update checks. Try again later.'**
  String get updateErrorRateLimited;

  /// No description provided for @updateErrorUnexpectedStatus.
  ///
  /// In en, this message translates to:
  /// **'GitHub answered with status {status}.'**
  String updateErrorUnexpectedStatus(String status);

  /// No description provided for @updateErrorInvalidJson.
  ///
  /// In en, this message translates to:
  /// **'GitHub returned something that was not valid JSON.'**
  String get updateErrorInvalidJson;

  /// No description provided for @updateErrorUnexpectedShape.
  ///
  /// In en, this message translates to:
  /// **'GitHub returned an unexpected response shape.'**
  String get updateErrorUnexpectedShape;

  /// No description provided for @updateErrorDownloadIncomplete.
  ///
  /// In en, this message translates to:
  /// **'The download ended early and the file is incomplete. Please try again.'**
  String get updateErrorDownloadIncomplete;

  /// No description provided for @updateErrorNotAnApk.
  ///
  /// In en, this message translates to:
  /// **'That download wasn\'t a valid app file. You may be on a network that intercepts downloads — try a different connection.'**
  String get updateErrorNotAnApk;

  /// No description provided for @updateErrorInstallerFailed.
  ///
  /// In en, this message translates to:
  /// **'The installer could not be opened: {detail}'**
  String updateErrorInstallerFailed(String detail);

  /// No description provided for @updateErrorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong: {detail}'**
  String updateErrorUnexpected(String detail);

  /// No description provided for @yearlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get yearlyTitle;

  /// No description provided for @moreYearlySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Every day of the year at a glance'**
  String get moreYearlySubtitle;

  /// No description provided for @yearNoData.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged in {year} yet.'**
  String yearNoData(String year);

  /// No description provided for @shareImage.
  ///
  /// In en, this message translates to:
  /// **'Share as image'**
  String get shareImage;

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not share that image.'**
  String get shareFailed;

  /// No description provided for @shareBadge.
  ///
  /// In en, this message translates to:
  /// **'Share this badge'**
  String get shareBadge;

  /// No description provided for @badgeLockedShare.
  ///
  /// In en, this message translates to:
  /// **'Earn this badge to share it.'**
  String get badgeLockedShare;

  /// No description provided for @sheetNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get sheetNoteLabel;

  /// No description provided for @sheetNoteHint.
  ///
  /// In en, this message translates to:
  /// **'What happened, how it felt…'**
  String get sheetNoteHint;

  /// No description provided for @sheetSaveNote.
  ///
  /// In en, this message translates to:
  /// **'Save note'**
  String get sheetSaveNote;

  /// No description provided for @sheetNoteSaved.
  ///
  /// In en, this message translates to:
  /// **'Note saved'**
  String get sheetNoteSaved;

  /// Section heading when the statistics are not about the current month
  ///
  /// In en, this message translates to:
  /// **'{month}'**
  String statsMonthOf(String month);

  /// No description provided for @sheetAddNote.
  ///
  /// In en, this message translates to:
  /// **'Add a note'**
  String get sheetAddNote;

  /// No description provided for @a11yDayCell.
  ///
  /// In en, this message translates to:
  /// **'{date}, {status}'**
  String a11yDayCell(String date, String status);

  /// No description provided for @a11yDayCellWithNote.
  ///
  /// In en, this message translates to:
  /// **'{date}, {status}, has a note'**
  String a11yDayCellWithNote(String date, String status);

  /// No description provided for @a11yDayUnlogged.
  ///
  /// In en, this message translates to:
  /// **'not logged'**
  String get a11yDayUnlogged;

  /// No description provided for @a11yDayFuture.
  ///
  /// In en, this message translates to:
  /// **'in the future'**
  String get a11yDayFuture;

  /// No description provided for @a11ySliceSelected.
  ///
  /// In en, this message translates to:
  /// **'{label}, {count} days, selected'**
  String a11ySliceSelected(String label, int count);

  /// No description provided for @a11ySlice.
  ///
  /// In en, this message translates to:
  /// **'{label}, {count} days'**
  String a11ySlice(String label, int count);

  /// No description provided for @a11yBadgeEarned.
  ///
  /// In en, this message translates to:
  /// **'{title}, earned {count} times, tap to share'**
  String a11yBadgeEarned(String title, int count);

  /// No description provided for @a11yBadgeLocked.
  ///
  /// In en, this message translates to:
  /// **'{title}, not earned yet'**
  String a11yBadgeLocked(String title);

  /// No description provided for @startupFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Don\'t Drink couldn\'t start'**
  String get startupFailedTitle;

  /// No description provided for @startupFailedBody.
  ///
  /// In en, this message translates to:
  /// **'Your data is safe and has not been changed. Please report this error.'**
  String get startupFailedBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
