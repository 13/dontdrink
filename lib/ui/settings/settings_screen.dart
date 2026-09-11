import 'package:dont_drink/core/models/day_entry.dart';
import 'package:dont_drink/data/repositories/entry_repository.dart';
import 'package:dont_drink/data/repositories/mode_repository.dart';
import 'package:dont_drink/services/export_import_service.dart';
import 'package:dont_drink/ui/settings/widgets/modes_section.dart';
import 'package:dont_drink/ui/widgets/app_card.dart';
import 'package:dont_drink/ui/widgets/section_header.dart';
import 'package:dont_drink/viewmodels/mode_viewmodel.dart';
import 'package:dont_drink/viewmodels/settings_viewmodel.dart';
import 'package:dont_drink/viewmodels/tracker_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SettingsViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const SectionHeader('Modes'),
            const ModesSection(),
            const SizedBox(height: 24),
            const SectionHeader('Appearance'),
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
                        title: Text(_themeLabel(mode)),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader('Daily Reminder'),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                children: [
                  SwitchListTile(
                    value: vm.notificationsEnabled,
                    onChanged: (enabled) =>
                        _toggleNotifications(context, enabled),
                    title: const Text('Daily reminder'),
                    subtitle: const Text('A gentle nudge to log your day'),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  ListTile(
                    enabled: vm.notificationsEnabled,
                    leading: const Icon(Icons.access_time),
                    title: const Text('Reminder time'),
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
            const SectionHeader('Data'),
            const _DataSection(),
            const SizedBox(height: 24),
            const SectionHeader('About'),
            const _AboutCard(),
          ],
        ),
      ),
    );
  }

  String _themeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.system => 'System default',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  Future<void> _toggleNotifications(
      BuildContext context, bool enabled) async {
    final vm = context.read<SettingsViewModel>();
    final result = await vm.setNotificationsEnabled(enabled);
    if (enabled && !result && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification permission was not granted.'),
        ),
      );
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final vm = context.read<SettingsViewModel>();
    final picked = await showTimePicker(
      context: context,
      initialTime: vm.reminderTime,
    );
    if (picked != null) {
      await vm.setReminderTime(picked);
    }
  }
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
            title: const Text('Export data'),
            subtitle: const Text('Save a backup of all your logs as JSON'),
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
            title: const Text('Import data'),
            subtitle: const Text('Restore logs from a backup file'),
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
    try {
      final modeVm = context.read<ModeViewModel>();
      final repo = EntryRepository();
      final modes = modeVm.allAvailableModes;
      final byMode = <String, List<DayEntry>>{
        for (final mode in modes) mode.id: await repo.getAll(mode),
      };
      await _service.export(modes: modes, entriesByMode: byMode);
    } catch (e) {
      if (mounted) {
        _showSnack('Export failed: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _confirmImport() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import data'),
        content: const Text(
          'Importing a backup will merge its entries with your current data, '
          'across all modes. Days already logged will be overwritten with the '
          'values from the file. Days not present in the file are left '
          'unchanged.\n\nContinue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _import();
  }

  Future<void> _import() async {
    setState(() => _importing = true);
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
            final base =
                'Imported $count ${count == 1 ? "entry" : "entries"}';
            _showSnack(
              skipped > 0
                  ? '$base. $skipped skipped — some modes in this backup '
                      'could not be restored.'
                  : '$base successfully.',
            );
          }
        case ImportCancelled():
          break; // user dismissed the picker — do nothing
        case ImportError(:final message):
          _showSnack(message, isError: true);
      }
    } catch (e) {
      if (mounted) _showSnack('Import failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

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
              'Version ${_info!.version} (build ${_info!.buildNumber})',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Built on 2026-06-04',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Icon(Icons.lock_outline,
                  size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'All data is stored privately on this device. '
                  'No account, no cloud, fully offline.',
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
