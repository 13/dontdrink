import 'dart:io' show Platform;

import 'package:dont_drink/ui/widgets/app_card.dart';
import 'package:dont_drink/viewmodels/update_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The Settings ▸ Updates card. One row per [UpdateState].
///
/// Android-only: this app is distributed as a sideloaded APK, and an iOS build
/// cannot install one, so the section hides itself entirely rather than
/// offering a control that cannot work.
class UpdateSection extends StatelessWidget {
  const UpdateSection({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Platform.isAndroid) return const SizedBox.shrink();

    final vm = context.watch<UpdateViewModel>();
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: switch (vm.state) {
        UpdateIdle() => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: const Icon(Icons.system_update_outlined),
            title: const Text('Check for updates'),
            subtitle: const Text('Looks for a newer release on GitHub'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.read<UpdateViewModel>().checkNow(),
          ),
        UpdateChecking() => const ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 12),
            leading: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: Text('Checking for updates…'),
          ),
        UpdateUpToDate(:final currentVersion) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: Icon(Icons.check_circle_outline,
                color: theme.colorScheme.primary),
            title: const Text("You're up to date"),
            subtitle: Text('Version $currentVersion is the latest release'),
            trailing: TextButton(
              onPressed: () => context.read<UpdateViewModel>().checkNow(),
              child: const Text('Check again'),
            ),
          ),
        UpdateAvailable(:final release) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                leading: Icon(Icons.system_update,
                    color: theme.colorScheme.primary),
                title: Text('Version ${release.version} is available'),
                subtitle: Text(
                  release.apkSizeBytes > 0
                      ? '${_formatBytes(release.apkSizeBytes)} download'
                      : 'Tap to download and install',
                ),
              ),
              if (release.notes.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: Text(
                    release.notes.trim(),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () =>
                          context.read<UpdateViewModel>().skipAvailableVersion(),
                      child: const Text('Later'),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () =>
                          context.read<UpdateViewModel>().download(),
                      icon: const Icon(Icons.download),
                      label: const Text('Download'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        UpdateDownloading(:final release, :final progress) => Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Downloading ${release.version}…',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 6),
                Text(
                  progress == null
                      ? 'Downloading…'
                      : '${(progress * 100).round()}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        UpdateReadyToInstall(:final release) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: Icon(Icons.download_done, color: theme.colorScheme.primary),
            title: Text('Version ${release.version} is ready'),
            subtitle: const Text(
                'Android will ask you to confirm the installation'),
            trailing: FilledButton(
              onPressed: () => context.read<UpdateViewModel>().install(),
              child: const Text('Install'),
            ),
          ),
        UpdateError(:final message) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: Icon(Icons.error_outline, color: theme.colorScheme.error),
            title: const Text("Couldn't check for updates"),
            subtitle: Text(message),
            trailing: TextButton(
              onPressed: () => context.read<UpdateViewModel>().checkNow(),
              child: const Text('Retry'),
            ),
          ),
      },
    );
  }

  static String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (bytes >= 1024) return '${(bytes / 1024).round()} KB';
    return '$bytes B';
  }
}
