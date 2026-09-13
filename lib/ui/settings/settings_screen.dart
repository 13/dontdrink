import 'dart:io' show Platform;
import 'dart:ui' show PlatformDispatcher;

import 'package:dont_drink/core/models/day_entry.dart';
import 'package:dont_drink/data/repositories/entry_repository.dart';
import 'package:dont_drink/data/repositories/mode_repository.dart';
import 'package:dont_drink/services/export_import_service.dart';
import 'package:dont_drink/ui/settings/widgets/modes_section.dart';
import 'package:dont_drink/ui/settings/widgets/update_section.dart';
import 'package:dont_drink/ui/widgets/app_card.dart';
import 'package:dont_drink/ui/widgets/section_header.dart';
import 'package:dont_drink/viewmodels/mode_viewmodel.dart';
import 'package:dont_drink/viewmodels/settings_viewmodel.dart';
import 'package:dont_drink/viewmodels/tracker_viewmodel.dart';
import 'package:dont_drink/l10n/app_localizations.dart';
import 'package:dont_drink/l10n/supported_locales.dart';
import 'package:dont_drink/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            SectionHeader(l10n.settingsModes),
            const ModesSection(),
            const SizedBox(height: 24),
            SectionHeader(l10n.settingsAppearance),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: RadioGroup<ThemeMode>(
                groupValue: vm.themeMode,
                onChanged: (m) =>
                    context.read<SettingsViewModel>().setThemeMode(m!),
                child: Column(
                  children: [
                    for (final mode in ThemeMode.values)
                      RadioListTile<ThemeMode>(
                        value: mode,
                        title: Text(_themeLabel(l10n, mode)),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SectionHeader(l10n.settingsLanguage),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: RadioGroup<String>(
                // 'system' rather than null: RadioGroup needs a value, and
                // "follow the system" is a real choice, not the absence of one.
                groupValue: vm.locale?.languageCode ?? _systemLanguage,
                onChanged: (code) => _setLanguage(context, code!),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      value: _systemLanguage,
                      title: Text(l10n.settingsLanguageSystem),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    for (final locale in kSupportedLocales)
                      RadioListTile<String>(
                        value: locale.languageCode,
                        title: Text(kLanguageNames[locale.languageCode]!),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SectionHeader(l10n.settingsDailyReminderSection),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  SwitchListTile(
                    value: vm.notificationsEnabled,
                    onChanged: (enabled) =>
                        _toggleNotifications(context, enabled),
                    title: Text(l10n.settingsDailyReminder),
                    subtitle: Text(l10n.settingsDailyReminderSubtitle),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  ListTile(
                    enabled: vm.notificationsEnabled,
                    leading: const Icon(Icons.access_time),
                    title: Text(l10n.settingsReminderTime),
                    trailing: Text(
                      vm.reminderTime.format(context),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    onTap: vm.notificationsEnabled
                        ? () => _pickTime(context)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SectionHeader(l10n.settingsData),
            const _DataSection(),
            if (Platform.isAndroid) ...[
              const SizedBox(height: 24),
              SectionHeader(l10n.settingsUpdates),
              const UpdateSection(),
            ],
            const SizedBox(height: 24),
            SectionHeader(l10n.settingsAbout),
            const _AboutCard(),
          ],
        ),
      ),
    );
  }

  static const String _systemLanguage = 'system';

  String _themeLabel(AppLocalizations l10n, ThemeMode mode) => switch (mode) {
        ThemeMode.system => l10n.settingsThemeSystem,
        ThemeMode.light => l10n.settingsThemeLight,
        ThemeMode.dark => l10n.settingsThemeDark,
      };

  /// Apply a language choice and keep the scheduled reminder in step.
  ///
  /// The reminder's text was baked in when it was scheduled, so it has to be
  /// re-scheduled in the new language — using strings loaded for the new
  /// locale, not the ones from the widget tree, which still speaks the old one.
  Future<void> _setLanguage(BuildContext context, String code) async {
    final vm = context.read<SettingsViewModel>();
    final locale = code == _systemLanguage ? null : Locale(code);
    await vm.setLocale(locale);

    final effective = locale ?? _systemLocale();
    final newL10n = await AppLocalizations.delegate.load(effective);
    await vm.refreshReminderCopy(_reminderCopy(newL10n));
  }

  /// The device language, narrowed to one the app ships.
  static Locale _systemLocale() {
    final device = PlatformDispatcher.instance.locale;
    return kSupportedLocales.firstWhere(
      (l) => l.languageCode == device.languageCode,
      orElse: () => kSupportedLocales.first,
    );
  }

  Future<void> _toggleNotifications(
      BuildContext context, bool enabled) async {
    final vm = context.read<SettingsViewModel>();
    final l10n = AppLocalizations.of(context);
    final result = await vm.setNotificationsEnabled(
      enabled,
      copy: _reminderCopy(l10n),
    );
    if (enabled && !result && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsNotificationDenied)),
      );
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final vm = context.read<SettingsViewModel>();
    final copy = _reminderCopy(AppLocalizations.of(context));
    final picked = await showTimePicker(
      context: context,
      initialTime: vm.reminderTime,
    );
    if (picked != null) {
      await vm.setReminderTime(picked, copy: copy);
    }
  }

  static ReminderCopy _reminderCopy(AppLocalizations l10n) => ReminderCopy(
        title: l10n.appTitle,
        body: l10n.notificationBody,
        channelName: l10n.notificationChannelName,
        channelDescription: l10n.notificationChannelDescription,
      );
}

// ── Data section ─────────────────────────────────────────────────────────────

class _DataSection extends StatefulWidget {
  const _DataSection();

  @override
  State<_DataSection> createState() => _DataSectionState();
}

class _DataSectionState extends State<_DataSection> {
  static const _service = ExportImportService();
  bool _exporting = false;
  bool _importing = false;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          ListTile(
            leading: _exporting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_outlined),
            title: Text(AppLocalizations.of(context).settingsExport),
            subtitle:
                Text(AppLocalizations.of(context).settingsExportSubtitle),
            trailing: const Icon(Icons.chevron_right),
            enabled: !_exporting && !_importing,
            onTap: _export,
          ),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: _importing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined),
            title: Text(AppLocalizations.of(context).settingsImport),
            subtitle:
                Text(AppLocalizations.of(context).settingsImportSubtitle),
            trailing: const Icon(Icons.chevron_right),
            enabled: !_exporting && !_importing,
            onTap: _confirmImport,
          ),
        ],
      ),
    );
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    final l10n = AppLocalizations.of(context);
    try {
      final modeVm = context.read<ModeViewModel>();
      final repo = EntryRepository();
      final modes = modeVm.allAvailableModes;
      final byMode = <String, List<DayEntry>>{
        for (final mode in modes) mode.id: await repo.getAll(mode),
      };
      await _service.export(
        modes: modes,
        entriesByMode: byMode,
        shareSubject: l10n.backupShareSubject,
      );
    } catch (e) {
      if (mounted) {
        _showSnack(l10n.settingsExportFailed('$e'), isError: true);
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _confirmImport() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(l10n.settingsImport),
          content: Text(l10n.settingsImportConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.commonImport),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    await _import();
  }

  Future<void> _import() async {
    setState(() => _importing = true);
    final l10n = AppLocalizations.of(context);
    try {
      final repo = EntryRepository();
      final result = await _service.import(
        entries: repo,
        modes: ModeRepository(entries: repo),
      );

      if (!mounted) return;

      switch (result) {
        case ImportSuccess(:final count, :final skipped):
          // Reload the ViewModels so the dashboard/calendar/mode list reflect
          // changes, including any custom modes the backup recreated.
          await context.read<TrackerViewModel>().load();
          if (mounted) await context.read<ModeViewModel>().load();
          if (mounted) {
            final base = l10n.settingsImportedCount(count);
            _showSnack(
              skipped > 0
                  ? l10n.settingsImportedSkipped(base, skipped)
                  : l10n.settingsImportedSuccess(base),
            );
          }
        case ImportCancelled():
          break; // user dismissed the picker — do nothing
        case ImportError():
          _showSnack(_importErrorMessage(l10n, result), isError: true);
      }
    } catch (e) {
      if (mounted) _showSnack(l10n.settingsImportFailed('$e'), isError: true);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  static String _importErrorMessage(AppLocalizations l10n, ImportError e) =>
      switch (e.failure) {
        ImportFailure.notABackup => l10n.importErrorNotABackup,
        ImportFailure.missingEntries => l10n.importErrorMissingEntries,
        ImportFailure.partial =>
          l10n.importErrorPartial(e.count, e.detail ?? ''),
        ImportFailure.unreadable => l10n.importErrorUnreadable,
        ImportFailure.readFailed => l10n.importErrorReadFailed(e.detail ?? ''),
        ImportFailure.invalidJson => l10n.importErrorInvalidJson,
      };

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }
}

// ── About card ────────────────────────────────────────────────────────────────

class _AboutCard extends StatefulWidget {
  const _AboutCard();

  @override
  State<_AboutCard> createState() => _AboutCardState();
}

class _AboutCardState extends State<_AboutCard> {
  /// Stamped by the release workflow with --dart-define=BUILD_DATE. A local
  /// build leaves it empty and the line is hidden, which is better than the
  /// hardcoded date this replaced — that one had been wrong for months.
  static const String _buildDate = String.fromEnvironment('BUILD_DATE');

  PackageInfo? _info;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _info = info);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/dontdrink.png',
            height: 72,
          ),
          const SizedBox(height: 16),
          if (_info != null) ...[
            Text(
              AppLocalizations.of(context)
                  .settingsVersion(_info!.version, _info!.buildNumber),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (_buildDate.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context).settingsBuiltOn(_buildDate),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Icon(Icons.lock_outline,
                  size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppLocalizations.of(context).settingsPrivacyBody,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
