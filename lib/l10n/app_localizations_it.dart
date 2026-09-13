// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Don\'t Drink';

  @override
  String get navDashboard => 'Panoramica';

  @override
  String get navAwards => 'Premi';

  @override
  String get navStats => 'Statistiche';

  @override
  String get navSettings => 'Impostazioni';

  @override
  String get commonCancel => 'Annulla';

  @override
  String get commonDelete => 'Elimina';

  @override
  String get commonSave => 'Salva';

  @override
  String get commonRename => 'Rinomina';

  @override
  String get commonRetry => 'Riprova';

  @override
  String get commonLater => 'Più tardi';

  @override
  String get commonImport => 'Importa';

  @override
  String get commonInstall => 'Installa';

  @override
  String get commonDownload => 'Scarica';

  @override
  String dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni',
      one: '1 giorno',
    );
    return '$_temp0';
  }

  @override
  String dayUnit(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'giorni',
      one: 'giorno',
    );
    return '$_temp0';
  }

  @override
  String get dashboardNextAchievement => 'Prossimo traguardo';

  @override
  String get dashboardLogToday => 'Registra oggi';

  @override
  String get dashboardHowDidTodayGo => 'Com\'è andata oggi?';

  @override
  String get streakCurrent => '🔥 Serie attuale';

  @override
  String get streakStart => 'Inizia la tua serie';

  @override
  String streakOf(String label) {
    return 'serie $label';
  }

  @override
  String get streakBest => 'record';

  @override
  String get statCurrentStreak => 'Serie attuale';

  @override
  String get statLongestStreak => 'Serie più lunga';

  @override
  String get statTotalCleanDays => 'Giorni puliti totali';

  @override
  String get monthNoDaysLogged => 'Nessun giorno registrato questo mese.';

  @override
  String get achievementsTitle => 'Traguardi';

  @override
  String get tabBadges => 'Distintivi';

  @override
  String get tabRecovery => 'Recupero';

  @override
  String badgesUnlockedOf(int unlocked, int total) {
    return '$unlocked di $total sbloccati';
  }

  @override
  String badgesEarnedTotal(int count) {
    return '$count ottenuti in totale';
  }

  @override
  String badgeTimesChip(int count) {
    return '×$count';
  }

  @override
  String badgeDayThreshold(int day) {
    return 'Giorno $day';
  }

  @override
  String badgeEarnedOn(String date) {
    return 'Ottenuto il $date';
  }

  @override
  String badgeFirstAndLast(String first, String last) {
    return 'Primo $first · ultimo $last';
  }

  @override
  String badgeEarnedBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Già ottenuto $count volte',
      one: 'Già ottenuto una volta',
    );
    return '$_temp0';
  }

  @override
  String badgeDaysToEarn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mancano $count giorni per ottenerlo',
      one: 'Manca 1 giorno per ottenerlo',
    );
    return '$_temp0';
  }

  @override
  String badgeDaysToEarnAgain(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mancano $count giorni per ottenerlo di nuovo',
      one: 'Manca 1 giorno per ottenerlo di nuovo',
    );
    return '$_temp0';
  }

  @override
  String get badgeEarnedExclamation => 'Ottenuto!';

  @override
  String get recoveryNoTimelineForMode =>
      'Le modalità personalizzate non hanno un percorso di recupero.';

  @override
  String get unlockTitle => 'Traguardo sbloccato!';

  @override
  String get unlockTitleRepeat => 'Ottenuto di nuovo!';

  @override
  String unlockRepeatChip(int count) {
    return '$count× ottenuto';
  }

  @override
  String get unlockKeepGoing => 'Continua così';

  @override
  String get calendarTitle => 'Calendario';

  @override
  String calendarMonthStatistics(String month) {
    return 'Statistiche di $month';
  }

  @override
  String get calendarLogged => 'Registrati';

  @override
  String get calendarCleanRate => 'Percentuale pulita';

  @override
  String get weekdayMon => 'Lun';

  @override
  String get weekdayTue => 'Mar';

  @override
  String get weekdayWed => 'Mer';

  @override
  String get weekdayThu => 'Gio';

  @override
  String get weekdayFri => 'Ven';

  @override
  String get weekdaySat => 'Sab';

  @override
  String get weekdaySun => 'Dom';

  @override
  String get sheetLogThisDay => 'Registra questo giorno';

  @override
  String get sheetClearDay => 'Cancella questo giorno';

  @override
  String get factsTitle => 'Fatti';

  @override
  String get factOfTheDay => 'Fatto del giorno';

  @override
  String get factsNoneForMode => 'Questa modalità non ha ancora fatti.';

  @override
  String get factDidYouKnow => '⚠️  Lo sapevi?';

  @override
  String get factGoodNews => '✨  Buone notizie';

  @override
  String get factShowAnother => 'Mostrane un altro';

  @override
  String get motivationTitle => 'Motivazione';

  @override
  String get motivationInspireMe => 'Ispirami';

  @override
  String get recoveryTimelineTitle => 'Percorso di recupero';

  @override
  String recoveryIntro(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Sei a $count giorni di recupero. Ecco cosa sta facendo il tuo corpo.',
      one: 'Sei a 1 giorno di recupero. Ecco cosa sta facendo il tuo corpo.',
    );
    return '$_temp0';
  }

  @override
  String get recoveryNoStreak =>
      'Inizia una serie per avviare il tuo percorso di recupero.';

  @override
  String recoveryMilestonesReached(int reached, int total) {
    return '$reached di $total traguardi raggiunti';
  }

  @override
  String get tierBronze => 'Bronzo — La fase acuta';

  @override
  String get tierSilver => 'Argento — La fase di rigenerazione';

  @override
  String get tierGold => 'Oro — La fase di vitalità';

  @override
  String get tierDiamond => 'Diamante — Protezione a lungo termine';

  @override
  String get tierBronzeRange => 'Giorni da 1 a 7';

  @override
  String get tierSilverRange => 'Dalla settimana 2 al mese 3';

  @override
  String get tierGoldRange => 'Dal mese 6 all\'anno 2';

  @override
  String get tierDiamondRange => 'Dall\'anno 5 in poi';

  @override
  String get moreTitle => 'Altro';

  @override
  String get moreMotivationSubtitle => 'Una spinta quando serve';

  @override
  String get moreSettingsSubtitle => 'Modalità, tema, promemoria e privacy';

  @override
  String get statsTitle => 'Statistiche';

  @override
  String get statsQuickStats => 'Dati rapidi';

  @override
  String get statsThisMonth => 'Questo mese';

  @override
  String get statsEmpty =>
      'Registra qualche giorno per vedere qui le tue statistiche.';

  @override
  String statsDaysPerMonth(String label) {
    return 'Giorni $label al mese';
  }

  @override
  String get statsDayDistribution => 'Distribuzione dei giorni';

  @override
  String get statsOverview => 'Riepilogo';

  @override
  String statsDaysValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni',
      one: '1 giorno',
    );
    return '$_temp0';
  }

  @override
  String statsRateOf(String label) {
    return 'percentuale $label';
  }

  @override
  String get statsTotalDaysLogged => 'Giorni registrati totali';

  @override
  String get statsBestMonth => 'Mese migliore';

  @override
  String statsBestMonthValue(String month, int count) {
    return '$month ($count puliti)';
  }

  @override
  String get statsNoDataYet => 'Ancora nessun dato';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get settingsModes => 'Modalità';

  @override
  String get settingsAppearance => 'Aspetto';

  @override
  String get settingsLanguage => 'Lingua';

  @override
  String get settingsLanguageSystem => 'Lingua di sistema';

  @override
  String get settingsThemeSystem => 'Predefinito di sistema';

  @override
  String get settingsThemeLight => 'Chiaro';

  @override
  String get settingsThemeDark => 'Scuro';

  @override
  String get settingsDailyReminderSection => 'Promemoria giornaliero';

  @override
  String get settingsDailyReminder => 'Promemoria giornaliero';

  @override
  String get settingsDailyReminderSubtitle =>
      'Un piccolo richiamo per registrare la giornata';

  @override
  String get settingsReminderTime => 'Orario del promemoria';

  @override
  String get settingsNotificationDenied =>
      'L\'autorizzazione alle notifiche non è stata concessa.';

  @override
  String get settingsData => 'Dati';

  @override
  String get settingsUpdates => 'Aggiornamenti';

  @override
  String get settingsAbout => 'Informazioni';

  @override
  String get settingsExport => 'Esporta i dati';

  @override
  String get settingsExportSubtitle => 'Scegli dove salvare il backup JSON';

  @override
  String get settingsImport => 'Importa i dati';

  @override
  String get settingsImportSubtitle =>
      'Ripristina le registrazioni da un file di backup';

  @override
  String settingsExportFailed(String error) {
    return 'Esportazione non riuscita: $error';
  }

  @override
  String settingsImportFailed(String error) {
    return 'Importazione non riuscita: $error';
  }

  @override
  String get settingsImportConfirmBody =>
      'L\'importazione unirà le voci del backup ai tuoi dati attuali, in tutte le modalità. I giorni già registrati verranno sovrascritti con i valori del file. I giorni non presenti nel file restano invariati.\n\nContinuare?';

  @override
  String settingsImportedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count voci importate',
      one: '1 voce importata',
    );
    return '$_temp0';
  }

  @override
  String settingsImportedSuccess(String base) {
    return '$base — completato.';
  }

  @override
  String settingsImportedSkipped(String base, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count voci sono state saltate perché illeggibili.',
      one: '1 voce è stata saltata perché illeggibile.',
    );
    return '$base. $_temp0';
  }

  @override
  String settingsVersion(String version, String build) {
    return 'Versione $version (build $build)';
  }

  @override
  String settingsBuiltOn(String date) {
    return 'Compilata il $date';
  }

  @override
  String get settingsPrivacyBody =>
      'Tutti i tuoi dati restano privati su questo dispositivo. Nessun account, nessuna sincronizzazione cloud. L\'app contatta GitHub solo per cercare e scaricare gli aggiornamenti.';

  @override
  String get modesCreateCustom => 'Crea modalità personalizzata';

  @override
  String get modesCreateCustomSubtitle =>
      'Traccia qualsiasi abitudine con giorni puliti e ricadute';

  @override
  String get modesActive => 'Attiva';

  @override
  String modesDayStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'serie di $count giorni',
      one: 'serie di 1 giorno',
    );
    return '$_temp0';
  }

  @override
  String get modesOffDataKept => 'Disattivata — i tuoi dati restano';

  @override
  String modesDeleteTitle(String name) {
    return 'Eliminare $name?';
  }

  @override
  String get modesDeleteBodyEmpty =>
      'Questa modalità non ha giorni registrati. Verrà rimossa definitivamente.';

  @override
  String modesDeleteBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Questa modalità e i suoi $count giorni registrati verranno eliminati definitivamente. L\'operazione non può essere annullata.',
      one:
          'Questa modalità e il suo 1 giorno registrato verranno eliminati definitivamente. L\'operazione non può essere annullata.',
    );
    return '$_temp0';
  }

  @override
  String modesDeleteFailed(String error) {
    return 'Impossibile eliminare questa modalità: $error';
  }

  @override
  String get modesSwitchMode => 'Cambia modalità';

  @override
  String get modesManage => 'Gestisci modalità…';

  @override
  String modesStreakShort(int count) {
    return '$count g';
  }

  @override
  String get modeEditorNew => 'Nuova modalità';

  @override
  String get modeEditorRename => 'Rinomina modalità';

  @override
  String get modeEditorSubtitle =>
      'Le modalità personalizzate tracciano giorni puliti, scivoloni e ricadute.';

  @override
  String get modeEditorName => 'Nome';

  @override
  String get modeEditorNameHint => 'es. Niente zucchero';

  @override
  String get modeEditorIcon => 'Icona';

  @override
  String get modeEditorCreate => 'Crea modalità';

  @override
  String modeEditorSaveFailed(String error) {
    return 'Impossibile salvare questa modalità: $error';
  }

  @override
  String get updateCheck => 'Cerca aggiornamenti';

  @override
  String get updateCheckSubtitle => 'Cerca una versione più recente su GitHub';

  @override
  String get updateChecking => 'Ricerca aggiornamenti…';

  @override
  String get updateUpToDate => 'Sei aggiornato';

  @override
  String updateUpToDateSubtitle(String version) {
    return 'La versione $version è l\'ultima disponibile';
  }

  @override
  String get updateCheckAgain => 'Cerca di nuovo';

  @override
  String updateAvailable(String version) {
    return 'La versione $version è disponibile';
  }

  @override
  String updateDownloadSize(String size) {
    return '$size da scaricare';
  }

  @override
  String get updateTapToInstall => 'Tocca per scaricare e installare';

  @override
  String updateDownloadingVersion(String version) {
    return 'Download di $version…';
  }

  @override
  String get updateDownloading => 'Download in corso…';

  @override
  String updateReady(String version) {
    return 'La versione $version è pronta';
  }

  @override
  String get updateReadySubtitle =>
      'Android ti chiederà di confermare l\'installazione';

  @override
  String get updateCheckFailed => 'Impossibile cercare aggiornamenti';

  @override
  String get updateDownloadFailed => 'Download non riuscito';

  @override
  String get updateInstallFailed => 'Impossibile avviare l\'installazione';

  @override
  String get notificationChannelName => 'Promemoria giornaliero';

  @override
  String get notificationChannelDescription =>
      'Un piccolo richiamo per registrare la giornata.';

  @override
  String get notificationBody =>
      'Com\'è andata oggi? Tocca per registrare la giornata.';

  @override
  String get backupShareSubject => 'Don\'t Drink — backup dei dati';

  @override
  String get importErrorNotABackup =>
      'Questo file non sembra un backup di Don\'t Drink.';

  @override
  String get importErrorMissingEntries =>
      'Nel file di backup manca l\'elenco delle voci.';

  @override
  String importErrorPartial(int count, String error) {
    return 'Importazione non riuscita dopo $count voci: $error';
  }

  @override
  String get importErrorUnreadable =>
      'Impossibile leggere il file selezionato.';

  @override
  String importErrorReadFailed(String error) {
    return 'Lettura del file non riuscita: $error';
  }

  @override
  String get importErrorInvalidJson =>
      'Il file selezionato non è un JSON valido.';

  @override
  String get modesRuleSwitchFirst =>
      'Passa a un\'altra modalità prima di disattivare questa.';

  @override
  String get modesRuleKeepOne => 'Almeno una modalità deve restare attiva.';

  @override
  String cheerTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Giorno $count fatto',
      one: 'Giorno 1 fatto',
    );
    return '$_temp0';
  }

  @override
  String get cheerBody0 => 'Registrato. Oggi non serviva altro.';

  @override
  String get cheerBody1 => 'Un altro messo a segno.';

  @override
  String get cheerBody2 =>
      'Il progresso ha esattamente questo aspetto, senza clamore.';

  @override
  String get cheerBody3 => 'Esserci conta, anche nei giorni ordinari.';

  @override
  String get cheerBody4 => 'Oggi hai mantenuto la parola data a te stesso.';

  @override
  String get cheerClose => 'Fatto';

  @override
  String get comfortTitle => 'Oggi è registrato';

  @override
  String get comfortBody0 =>
      'È successo, e l\'hai comunque annotato. Non è poco.';

  @override
  String get comfortBody1 => 'Un giorno è un dato, non una sentenza.';

  @override
  String get comfortBody2 =>
      'Essere onesto con te stesso è la parte che continua a funzionare.';

  @override
  String get comfortBody3 => 'Domani è un giorno a sé. Comincia pulito.';

  @override
  String get comfortBody4 =>
      'Niente di tutto questo cancella i giorni che hai già tenuto.';

  @override
  String comfortKept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'I tuoi $count distintivi e la tua serie record restano tuoi.',
      one: 'Il tuo 1 distintivo e la tua serie record restano tuoi.',
      zero: 'La tua serie record resta.',
    );
    return '$_temp0';
  }

  @override
  String get comfortBoost => 'Ho bisogno di una spinta';

  @override
  String get comfortClose => 'Chiudi';

  @override
  String get moreCalendarSubtitle => 'Tutto il mese, con legenda e totali';

  @override
  String get updateErrorNoConnection =>
      'GitHub non è raggiungibile. Controlla la connessione.';

  @override
  String get updateErrorInsecureConnection =>
      'Impossibile stabilire una connessione sicura.';

  @override
  String get updateErrorConnectionInterrupted =>
      'La connessione si è interrotta. Riprova.';

  @override
  String get updateErrorTimedOut =>
      'La ricerca di aggiornamenti è scaduta. Riprova.';

  @override
  String get updateErrorNoReleases =>
      'Non è ancora stata pubblicata nessuna versione.';

  @override
  String get updateErrorRateLimited =>
      'GitHub sta limitando le ricerche di aggiornamenti. Riprova più tardi.';

  @override
  String updateErrorUnexpectedStatus(String status) {
    return 'GitHub ha risposto con lo stato $status.';
  }

  @override
  String get updateErrorInvalidJson =>
      'GitHub ha restituito qualcosa che non è JSON valido.';

  @override
  String get updateErrorUnexpectedShape =>
      'GitHub ha restituito una risposta di forma inattesa.';

  @override
  String get updateErrorDownloadIncomplete =>
      'Il download si è interrotto presto e il file è incompleto. Riprova.';

  @override
  String get updateErrorNotAnApk =>
      'Il file scaricato non è un\'app valida. Potresti essere su una rete che intercetta i download — prova un\'altra connessione.';

  @override
  String updateErrorInstallerFailed(String detail) {
    return 'Impossibile aprire l\'installazione: $detail';
  }

  @override
  String updateErrorUnexpected(String detail) {
    return 'Qualcosa è andato storto: $detail';
  }

  @override
  String get yearlyTitle => 'Anno';

  @override
  String get moreYearlySubtitle => 'Tutto l\'anno in un colpo d\'occhio';

  @override
  String yearNoData(String year) {
    return 'Per il $year non c\'è ancora nulla.';
  }

  @override
  String get shareImage => 'Condividi come immagine';

  @override
  String get shareFailed => 'Impossibile condividere l\'immagine.';

  @override
  String get shareBadge => 'Condividi questo distintivo';

  @override
  String get badgeLockedShare => 'Ottieni questo distintivo per condividerlo.';

  @override
  String get sheetNoteLabel => 'Nota (facoltativa)';

  @override
  String get sheetNoteHint => 'Cos\'è successo, come ti sei sentito…';

  @override
  String get sheetSaveNote => 'Salva la nota';

  @override
  String get sheetNoteSaved => 'Nota salvata';

  @override
  String statsMonthOf(String month) {
    return '$month';
  }

  @override
  String get sheetAddNote => 'Aggiungi una nota';

  @override
  String a11yDayCell(String date, String status) {
    return '$date, $status';
  }

  @override
  String a11yDayCellWithNote(String date, String status) {
    return '$date, $status, con nota';
  }

  @override
  String get a11yDayUnlogged => 'non registrato';

  @override
  String get a11yDayFuture => 'nel futuro';

  @override
  String a11ySliceSelected(String label, int count) {
    return '$label, $count giorni, selezionato';
  }

  @override
  String a11ySlice(String label, int count) {
    return '$label, $count giorni';
  }

  @override
  String a11yBadgeEarned(String title, int count) {
    return '$title, ottenuto $count volte, tocca per condividere';
  }

  @override
  String a11yBadgeLocked(String title) {
    return '$title, non ancora ottenuto';
  }

  @override
  String get welcomeTitle => 'Comincia da dove sei';

  @override
  String get welcomeBody =>
      'Tocca un giorno per registrarlo. I giorni puliti costruiscono una serie, e i distintivi si ottengono di nuovo ogni volta che li raggiungi — una ricaduta costa la serie, mai i distintivi.';

  @override
  String get welcomePrivacy => 'Tutto resta su questo dispositivo.';

  @override
  String get notesTitle => 'Note';

  @override
  String get moreNotesSubtitle =>
      'Quello che hai scritto nei giorni registrati';

  @override
  String get notesEmpty =>
      'Ancora nessuna nota. Scrivine una quando registri un giorno e comparirà qui.';

  @override
  String get settingsShareBackup => 'Condividi il backup';

  @override
  String get settingsShareBackupSubtitle =>
      'Invia il file JSON a un\'altra app';

  @override
  String get settingsExportSaved => 'Backup salvato';

  @override
  String get startupFailedTitle => 'Don\'t Drink non è riuscita ad avviarsi';

  @override
  String get startupFailedBody =>
      'I tuoi dati sono al sicuro e non sono stati modificati. Segnala questo errore.';
}
