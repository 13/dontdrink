import 'package:dont_drink/viewmodels/mode_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The dashboard's app-bar title: the active mode's name, tappable to switch
/// between enabled modes.
///
/// When only one mode is enabled it renders as a plain title — there is
/// nothing to switch to, so the affordance would be a lie.
class ModeSwitcher extends StatelessWidget {
  const ModeSwitcher({super.key, required this.onManageModes});

  /// Opens Settings, where modes are turned on and off.
  final VoidCallback onManageModes;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ModeViewModel>();
    final theme = Theme.of(context);
    final active = vm.activeMode;

    if (vm.enabledModes.length <= 1) {
      return Text(active.name);
    }

    return PopupMenuButton<String>(
      tooltip: 'Switch mode',
      position: PopupMenuPosition.under,
      onSelected: (value) {
        if (value == _manageValue) {
          onManageModes();
        } else {
          vm.setActive(value);
        }
      },
      itemBuilder: (context) => [
        for (final mode in vm.enabledModes)
          PopupMenuItem<String>(
            value: mode.id,
            child: Row(
              children: [
                Text(mode.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Expanded(child: Text(mode.name)),
                const SizedBox(width: 12),
                Text(
                  '${vm.streakFor(mode.id)} d',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.check,
                  size: 18,
                  color: mode.id == active.id
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                ),
              ],
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: _manageValue,
          child: Row(
            children: [
              Icon(Icons.tune, size: 18),
              SizedBox(width: 12),
              Text('Manage modes…'),
            ],
          ),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(active.name),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }

  static const _manageValue = '__manage__';
}
