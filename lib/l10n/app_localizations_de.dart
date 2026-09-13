// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Don\'t Drink';

  @override
  String get navDashboard => 'Übersicht';

  @override
  String get navAwards => 'Erfolge';

  @override
  String get navStats => 'Statistik';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String get commonCancel => 'Abbrechen';

  @override
  String get commonDelete => 'Löschen';

  @override
  String get commonSave => 'Speichern';

  @override
  String get commonRename => 'Umbenennen';

  @override
  String get commonRetry => 'Erneut versuchen';

  @override
  String get commonLater => 'Später';

  @override
  String get commonImport => 'Importieren';

  @override
  String get commonInstall => 'Installieren';

  @override
  String get commonDownload => 'Herunterladen';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String dayUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tage',
      one: 'Tag',
    );
    return '$_temp0';
  }

  @override
  String get dashboardNextAchievement => 'Nächster Erfolg';

  @override
  String get dashboardLogToday => 'Heute eintragen';

  @override
  String get dashboardHowDidTodayGo => 'Wie lief der Tag?';

  @override
  String get streakCurrent => '🔥 Aktuelle Serie';

  @override
  String get streakStart => 'Starte deine Serie';

  @override
  String streakOf(String label) {
    return '$label-Serie';
  }

  @override
  String get streakBest => 'Beste';

  @override
  String get statCurrentStreak => 'Aktuelle Serie';

  @override
  String get statLongestStreak => 'Längste Serie';

  @override
  String get statTotalCleanDays => 'Saubere Tage gesamt';

  @override
  String get monthNoDaysLogged => 'Diesen Monat noch keine Tage eingetragen.';

  @override
  String get achievementsTitle => 'Erfolge';

  @override
  String get tabBadges => 'Abzeichen';

  @override
  String get tabRecovery => 'Erholung';

  @override
  String badgesUnlockedOf(int unlocked, int total) {
    return '$unlocked von $total freigeschaltet';
  }

  @override
  String badgesEarnedTotal(int count) {
    return '$count insgesamt verdient';
  }

  @override
  String badgeTimesChip(int count) {
    return '×$count';
  }

  @override
  String badgeDayThreshold(int day) {
    return 'Tag $day';
  }

  @override
  String badgeEarnedOn(String date) {
    return 'Verdient am $date';
  }

  @override
  String badgeFirstAndLast(String first, String last) {
    return 'Zuerst $first · zuletzt $last';
  }

  @override
  String badgeEarnedBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Schon $count-mal verdient',
      one: 'Schon einmal verdient',
    );
    return '$_temp0';
  }

  @override
  String badgeDaysToEarn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Noch $count Tage bis zum Erfolg',
      one: 'Noch 1 Tag bis zum Erfolg',
    );
    return '$_temp0';
  }

  @override
  String badgeDaysToEarnAgain(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Noch $count Tage, um ihn erneut zu verdienen',
      one: 'Noch 1 Tag, um ihn erneut zu verdienen',
    );
    return '$_temp0';
  }

  @override
  String get badgeEarnedExclamation => 'Verdient!';

  @override
  String get recoveryNoTimelineForMode =>
      'Eigene Modi haben keinen Erholungsverlauf.';

  @override
  String get unlockTitle => 'Erfolg freigeschaltet!';

  @override
  String get unlockTitleRepeat => 'Erneut verdient!';

  @override
  String unlockRepeatChip(int count) {
    return '$count× verdient';
  }

  @override
  String get unlockKeepGoing => 'Weiter so';

  @override
  String get calendarTitle => 'Kalender';

  @override
  String calendarMonthStatistics(String month) {
    return 'Statistik für $month';
  }

  @override
  String get calendarLogged => 'Eingetragen';

  @override
  String get calendarCleanRate => 'Saubere Quote';

  @override
  String get weekdayMon => 'Mo';

  @override
  String get weekdayTue => 'Di';

  @override
  String get weekdayWed => 'Mi';

  @override
  String get weekdayThu => 'Do';

  @override
  String get weekdayFri => 'Fr';

  @override
  String get weekdaySat => 'Sa';

  @override
  String get weekdaySun => 'So';

  @override
  String get sheetLogThisDay => 'Diesen Tag eintragen';

  @override
  String get sheetClearDay => 'Eintrag löschen';

  @override
  String get factsTitle => 'Fakten';

  @override
  String get factOfTheDay => 'Fakt des Tages';

  @override
  String get factsNoneForMode => 'Für diesen Modus gibt es noch keine Fakten.';

  @override
  String get factDidYouKnow => '⚠️  Wusstest du?';

  @override
  String get factGoodNews => '✨  Gute Nachricht';

  @override
  String get factShowAnother => 'Anderen anzeigen';

  @override
  String get motivationTitle => 'Motivation';

  @override
  String get motivationInspireMe => 'Inspirier mich';

  @override
  String get recoveryTimelineTitle => 'Erholungsverlauf';

  @override
  String recoveryIntro(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Du bist $count Tage in der Erholung. Das passiert gerade in deinem Körper.',
      one:
          'Du bist 1 Tag in der Erholung. Das passiert gerade in deinem Körper.',
    );
    return '$_temp0';
  }

  @override
  String get recoveryNoStreak =>
      'Starte eine Serie, um deine Erholung zu beginnen.';

  @override
  String recoveryMilestonesReached(int reached, int total) {
    return '$reached von $total Meilensteinen erreicht';
  }

  @override
  String get tierBronze => 'Bronze — Die akute Phase';

  @override
  String get tierSilver => 'Silber — Die Regenerationsphase';

  @override
  String get tierGold => 'Gold — Die Vitalitätsphase';

  @override
  String get tierDiamond => 'Diamant — Langfristiger Schutz';

  @override
  String get tierBronzeRange => 'Tag 1 bis 7';

  @override
  String get tierSilverRange => 'Woche 2 bis Monat 3';

  @override
  String get tierGoldRange => 'Monat 6 bis Jahr 2';

  @override
  String get tierDiamondRange => 'Ab Jahr 5';

  @override
  String get moreTitle => 'Mehr';

  @override
  String get moreMotivationSubtitle => 'Ein Schub, wenn du ihn brauchst';

  @override
  String get moreSettingsSubtitle => 'Modi, Design, Erinnerungen & Datenschutz';

  @override
  String get statsTitle => 'Statistik';

  @override
  String get statsQuickStats => 'Kurzübersicht';

  @override
  String get statsThisMonth => 'Dieser Monat';

  @override
  String get statsEmpty =>
      'Trage ein paar Tage ein, um hier deine Statistik zu sehen.';

  @override
  String statsDaysPerMonth(String label) {
    return '$label-Tage pro Monat';
  }

  @override
  String get statsDayDistribution => 'Verteilung der Tage';

  @override
  String get statsOverview => 'Überblick';

  @override
  String statsDaysValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String statsRateOf(String label) {
    return '$label-Quote';
  }

  @override
  String get statsTotalDaysLogged => 'Eingetragene Tage gesamt';

  @override
  String get statsBestMonth => 'Bester Monat';

  @override
  String statsBestMonthValue(String month, int count) {
    return '$month ($count sauber)';
  }

  @override
  String get statsNoDataYet => 'Noch keine Daten';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsModes => 'Modi';

  @override
  String get settingsAppearance => 'Darstellung';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsLanguageSystem => 'Systemsprache';

  @override
  String get settingsThemeSystem => 'Systemstandard';

  @override
  String get settingsThemeLight => 'Hell';

  @override
  String get settingsThemeDark => 'Dunkel';

  @override
  String get settingsDailyReminderSection => 'Tägliche Erinnerung';

  @override
  String get settingsDailyReminder => 'Tägliche Erinnerung';

  @override
  String get settingsDailyReminderSubtitle =>
      'Ein sanfter Anstoß, den Tag einzutragen';

  @override
  String get settingsReminderTime => 'Uhrzeit der Erinnerung';

  @override
  String get settingsNotificationDenied =>
      'Die Benachrichtigungsberechtigung wurde nicht erteilt.';

  @override
  String get settingsData => 'Daten';

  @override
  String get settingsUpdates => 'Updates';

  @override
  String get settingsAbout => 'Über';

  @override
  String get settingsExport => 'Daten exportieren';

  @override
  String get settingsExportSubtitle =>
      'Sicherung aller Einträge als JSON speichern';

  @override
  String get settingsImport => 'Daten importieren';

  @override
  String get settingsImportSubtitle =>
      'Einträge aus einer Sicherung wiederherstellen';

  @override
  String settingsExportFailed(String error) {
    return 'Export fehlgeschlagen: $error';
  }

  @override
  String settingsImportFailed(String error) {
    return 'Import fehlgeschlagen: $error';
  }

  @override
  String get settingsImportConfirmBody =>
      'Beim Import werden die Einträge der Sicherung mit deinen aktuellen Daten zusammengeführt, über alle Modi hinweg. Bereits eingetragene Tage werden mit den Werten aus der Datei überschrieben. Tage, die nicht in der Datei stehen, bleiben unverändert.\n\nFortfahren?';

  @override
  String settingsImportedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Einträge importiert',
      one: '1 Eintrag importiert',
    );
    return '$_temp0';
  }

  @override
  String settingsImportedSuccess(String base) {
    return '$base — erfolgreich.';
  }

  @override
  String settingsImportedSkipped(String base, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Einträge wurden übersprungen, weil sie nicht gelesen werden konnten.',
      one: '1 Eintrag wurde übersprungen, weil er nicht gelesen werden konnte.',
    );
    return '$base. $_temp0';
  }

  @override
  String settingsVersion(String version, String build) {
    return 'Version $version (Build $build)';
  }

  @override
  String settingsBuiltOn(String date) {
    return 'Erstellt am $date';
  }

  @override
  String get settingsPrivacyBody =>
      'Alle deine Daten bleiben privat auf diesem Gerät. Kein Konto, keine Cloud-Synchronisierung. Die App kontaktiert GitHub nur, um nach Updates zu suchen und sie herunterzuladen.';

  @override
  String get modesCreateCustom => 'Eigenen Modus erstellen';

  @override
  String get modesCreateCustomSubtitle =>
      'Jede Gewohnheit mit sauberen Tagen und Ausrutschern verfolgen';

  @override
  String get modesActive => 'Aktiv';

  @override
  String modesDayStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage Serie',
      one: '1 Tag Serie',
    );
    return '$_temp0';
  }

  @override
  String get modesOffDataKept => 'Aus — deine Daten bleiben erhalten';

  @override
  String modesDeleteTitle(String name) {
    return '$name löschen?';
  }

  @override
  String get modesDeleteBodyEmpty =>
      'Dieser Modus hat keine eingetragenen Tage. Er wird dauerhaft entfernt.';

  @override
  String modesDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Dieser Modus und seine $count eingetragenen Tage werden dauerhaft gelöscht. Das kann nicht rückgängig gemacht werden.',
      one:
          'Dieser Modus und sein 1 eingetragener Tag werden dauerhaft gelöscht. Das kann nicht rückgängig gemacht werden.',
    );
    return '$_temp0';
  }

  @override
  String modesDeleteFailed(String error) {
    return 'Modus konnte nicht gelöscht werden: $error';
  }

  @override
  String get modesSwitchMode => 'Modus wechseln';

  @override
  String get modesManage => 'Modi verwalten…';

  @override
  String modesStreakShort(int count) {
    return '$count T';
  }

  @override
  String get modeEditorNew => 'Neuer Modus';

  @override
  String get modeEditorRename => 'Modus umbenennen';

  @override
  String get modeEditorSubtitle =>
      'Eigene Modi verfolgen saubere Tage, Ausrutscher und Rückfälle.';

  @override
  String get modeEditorName => 'Name';

  @override
  String get modeEditorNameHint => 'z. B. Kein Zucker';

  @override
  String get modeEditorIcon => 'Symbol';

  @override
  String get modeEditorCreate => 'Modus erstellen';

  @override
  String modeEditorSaveFailed(String error) {
    return 'Modus konnte nicht gespeichert werden: $error';
  }

  @override
  String get updateCheck => 'Nach Updates suchen';

  @override
  String get updateCheckSubtitle =>
      'Sucht auf GitHub nach einer neueren Version';

  @override
  String get updateChecking => 'Suche nach Updates…';

  @override
  String get updateUpToDate => 'Du bist auf dem neuesten Stand';

  @override
  String updateUpToDateSubtitle(String version) {
    return 'Version $version ist die neueste Veröffentlichung';
  }

  @override
  String get updateCheckAgain => 'Erneut suchen';

  @override
  String updateAvailable(String version) {
    return 'Version $version ist verfügbar';
  }

  @override
  String updateDownloadSize(String size) {
    return '$size Download';
  }

  @override
  String get updateTapToInstall => 'Tippen zum Herunterladen und Installieren';

  @override
  String updateDownloadingVersion(String version) {
    return 'Lade $version herunter…';
  }

  @override
  String get updateDownloading => 'Wird heruntergeladen…';

  @override
  String updateReady(String version) {
    return 'Version $version ist bereit';
  }

  @override
  String get updateReadySubtitle =>
      'Android fragt dich, ob du die Installation bestätigst';

  @override
  String get updateCheckFailed => 'Update-Suche fehlgeschlagen';

  @override
  String get updateDownloadFailed => 'Download fehlgeschlagen';

  @override
  String get updateInstallFailed =>
      'Installationsprogramm konnte nicht gestartet werden';

  @override
  String get notificationChannelName => 'Tägliche Erinnerung';

  @override
  String get notificationChannelDescription =>
      'Ein sanfter Anstoß, den Tag einzutragen.';

  @override
  String get notificationBody =>
      'Wie lief der Tag? Tippen, um ihn einzutragen.';

  @override
  String get backupShareSubject => 'Don\'t Drink — Datensicherung';

  @override
  String get importErrorNotABackup =>
      'Diese Datei sieht nicht wie eine Don\'t-Drink-Sicherung aus.';

  @override
  String get importErrorMissingEntries =>
      'In der Sicherungsdatei fehlt die Liste der Einträge.';

  @override
  String importErrorPartial(int count, String error) {
    return 'Import nach $count Einträgen fehlgeschlagen: $error';
  }

  @override
  String get importErrorUnreadable =>
      'Die ausgewählte Datei konnte nicht gelesen werden.';

  @override
  String importErrorReadFailed(String error) {
    return 'Datei konnte nicht gelesen werden: $error';
  }

  @override
  String get importErrorInvalidJson =>
      'Die ausgewählte Datei ist kein gültiges JSON.';

  @override
  String get modesRuleSwitchFirst =>
      'Wechsle zu einem anderen Modus, bevor du diesen ausschaltest.';

  @override
  String get modesRuleKeepOne =>
      'Mindestens ein Modus muss eingeschaltet bleiben.';

  @override
  String cheerTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tag $count geschafft',
      one: 'Tag 1 geschafft',
    );
    return '$_temp0';
  }

  @override
  String get cheerBody0 => 'Eingetragen. Mehr war heute nicht nötig.';

  @override
  String get cheerBody1 => 'Noch einer auf dem Konto.';

  @override
  String get cheerBody2 =>
      'Genau so sieht Fortschritt aus, ganz unspektakulär.';

  @override
  String get cheerBody3 => 'Dranbleiben zählt, auch an gewöhnlichen Tagen.';

  @override
  String get cheerBody4 => 'Du hast dir heute Wort gehalten.';

  @override
  String get cheerClose => 'Fertig';

  @override
  String get comfortTitle => 'Heute ist eingetragen';

  @override
  String get comfortBody0 =>
      'Es ist passiert, und du hast es trotzdem notiert. Das kostet etwas.';

  @override
  String get comfortBody1 => 'Ein Tag ist ein Datenpunkt, kein Urteil.';

  @override
  String get comfortBody2 =>
      'Ehrlich zu dir selbst zu sein ist der Teil, der weiter wirkt.';

  @override
  String get comfortBody3 => 'Morgen ist ein eigener Tag. Er fängt sauber an.';

  @override
  String get comfortBody4 =>
      'Nichts davon löscht die Tage, die du schon durchgehalten hast.';

  @override
  String comfortKept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Deine $count Abzeichen und deine beste Serie bleiben dir.',
      one: 'Dein 1 Abzeichen und deine beste Serie bleiben dir.',
      zero: 'Deine beste Serie bleibt bestehen.',
    );
    return '$_temp0';
  }

  @override
  String get comfortBoost => 'Ich brauch was Aufbauendes';

  @override
  String get comfortClose => 'Schließen';

  @override
  String get moreCalendarSubtitle => 'Der ganze Monat, mit Legende und Summen';

  @override
  String get updateErrorNoConnection =>
      'GitHub war nicht erreichbar. Prüfe deine Verbindung.';

  @override
  String get updateErrorInsecureConnection =>
      'Es konnte keine sichere Verbindung aufgebaut werden.';

  @override
  String get updateErrorConnectionInterrupted =>
      'Die Verbindung wurde unterbrochen. Bitte versuche es erneut.';

  @override
  String get updateErrorTimedOut =>
      'Die Update-Suche hat zu lange gedauert. Bitte versuche es erneut.';

  @override
  String get updateErrorNoReleases =>
      'Es wurden noch keine Versionen veröffentlicht.';

  @override
  String get updateErrorRateLimited =>
      'GitHub begrenzt die Update-Suche gerade. Versuche es später erneut.';

  @override
  String updateErrorUnexpectedStatus(String status) {
    return 'GitHub hat mit Status $status geantwortet.';
  }

  @override
  String get updateErrorInvalidJson =>
      'GitHub hat kein gültiges JSON zurückgegeben.';

  @override
  String get updateErrorUnexpectedShape =>
      'GitHub hat eine unerwartete Antwortstruktur zurückgegeben.';

  @override
  String get updateErrorDownloadIncomplete =>
      'Der Download brach früh ab, die Datei ist unvollständig. Bitte versuche es erneut.';

  @override
  String get updateErrorNotAnApk =>
      'Der Download war keine gültige App-Datei. Vielleicht bist du in einem Netzwerk, das Downloads abfängt — probiere eine andere Verbindung.';

  @override
  String updateErrorInstallerFailed(String detail) {
    return 'Das Installationsprogramm ließ sich nicht öffnen: $detail';
  }

  @override
  String updateErrorUnexpected(String detail) {
    return 'Etwas ist schiefgelaufen: $detail';
  }

  @override
  String get yearlyTitle => 'Jahr';

  @override
  String get moreYearlySubtitle => 'Das ganze Jahr auf einen Blick';

  @override
  String yearNoData(String year) {
    return 'Für $year ist noch nichts eingetragen.';
  }

  @override
  String get shareImage => 'Als Bild teilen';

  @override
  String get shareFailed => 'Das Bild konnte nicht geteilt werden.';

  @override
  String get shareBadge => 'Dieses Abzeichen teilen';

  @override
  String get badgeLockedShare => 'Verdiene dieses Abzeichen, um es zu teilen.';

  @override
  String get sheetNoteLabel => 'Notiz (optional)';

  @override
  String get sheetNoteHint => 'Was war los, wie hat es sich angefühlt…';

  @override
  String get sheetSaveNote => 'Notiz speichern';

  @override
  String get sheetNoteSaved => 'Notiz gespeichert';

  @override
  String statsMonthOf(String month) {
    return '$month';
  }

  @override
  String get sheetAddNote => 'Notiz hinzufügen';

  @override
  String a11yDayCell(String date, String status) {
    return '$date, $status';
  }

  @override
  String a11yDayCellWithNote(String date, String status) {
    return '$date, $status, mit Notiz';
  }

  @override
  String get a11yDayUnlogged => 'nicht eingetragen';

  @override
  String get a11yDayFuture => 'in der Zukunft';

  @override
  String a11ySliceSelected(String label, int count) {
    return '$label, $count Tage, ausgewählt';
  }

  @override
  String a11ySlice(String label, int count) {
    return '$label, $count Tage';
  }

  @override
  String a11yBadgeEarned(String title, int count) {
    return '$title, $count-mal verdient, zum Teilen tippen';
  }

  @override
  String a11yBadgeLocked(String title) {
    return '$title, noch nicht verdient';
  }

  @override
  String get welcomeTitle => 'Fang dort an, wo du bist';

  @override
  String get welcomeBody =>
      'Tippe auf einen Tag, um ihn einzutragen. Saubere Tage bauen eine Serie auf, und Abzeichen verdienst du jedes Mal neu, wenn du sie erreichst — ein Rückfall kostet die Serie, nie die Abzeichen.';

  @override
  String get welcomePrivacy => 'Alles bleibt auf diesem Gerät.';

  @override
  String get openCalendar => 'Kalender öffnen';

  @override
  String get notesTitle => 'Notizen';

  @override
  String get moreNotesSubtitle => 'Was du an eingetragenen Tagen notiert hast';

  @override
  String get notesEmpty =>
      'Noch keine Notizen. Schreib beim Eintragen eines Tages eine, dann steht sie hier.';

  @override
  String get startupFailedTitle => 'Don\'t Drink konnte nicht starten';

  @override
  String get startupFailedBody =>
      'Deine Daten sind sicher und unverändert. Bitte melde diesen Fehler.';
}
