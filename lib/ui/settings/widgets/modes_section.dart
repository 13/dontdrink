import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/ui/modes/custom_mode_editor.dart';
import 'package:dont_drink/ui/widgets/app_card.dart';
import 'package:dont_drink/viewmodels/mode_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The Settings ▸ Modes card: turn modes on and off, switch the active one,
/// and manage custom modes.
class ModesSection extends StatelessWidget {
  const ModesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ModeViewModel>();

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          for (final mode in vm.allAvailableModes)
            _ModeTile(mode: mode, vm: vm),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Create custom mode'),
            subtitle: const Text('Track any habit with clean days and slips'),
            onTap: () => CustomModeEditor.show(context),
          ),
        ],
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({required this.mode, required this.vm});

  final ModeDefinition mode;
  final ModeViewModel vm;

  bool get _enabled => vm.enabledModes.any((m) => m.id == mode.id);
  bool get _isActive => vm.activeMode.id == mode.id;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final streak = vm.streakFor(mode.id);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: Text(mode.emoji, style: const TextStyle(fontSize: 22)),
      title: Row(
        children: [
          Flexible(child: Text(mode.name)),
          if (_isActive) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Active',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: _enabled
          ? Text('$streak day streak')
          : const Text('Off — your data is kept'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!mode.isBuiltIn)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Rename',
              onPressed: () => CustomModeEditor.show(context, existing: mode),
            ),
          if (!mode.isBuiltIn)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(context),
            ),
          Switch(
            value: _enabled,
            onChanged: (on) => _toggle(context, on),
          ),
        ],
      ),
      onTap: _enabled && !_isActive ? () => vm.setActive(mode.id) : null,
    );
  }

  Future<void> _toggle(BuildContext context, bool on) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await vm.setEnabled(mode.id, on);
    } on ModeRuleError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final count = await vm.loggedDayCount(mode.id);
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${mode.name}?'),
        content: Text(
          count == 0
              ? 'This mode has no logged days. It will be removed permanently.'
              : 'This will permanently delete this mode and its '
                  '$count logged ${count == 1 ? "day" : "days"}. '
                  'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await vm.deleteCustom(mode.id);
    }
  }
}
