import 'dart:io' show Platform;

import 'package:dont_drink/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: switch (vm.state) {
        UpdateIdle() => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: const Icon(Icons.system_update_outlined),
            title: Text(l10n.updateCheck),
            subtitle: Text(l10n.updateCheckSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.read<UpdateViewModel>().checkNow(),
          ),
        UpdateChecking() => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            title: Text(l10n.updateChecking),
          ),
        UpdateUpToDate(:final currentVersion) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: Icon(Icons.check_circle_outline,
                color: theme.colorScheme.primary),
            title: Text(l10n.updateUpToDate),
            subtitle: Text(l10n.updateUpToDateSubtitle(currentVersion)),
            trailing: TextButton(
              onPressed: () => context.read<UpdateViewModel>().checkNow(),
              child: Text(l10n.updateCheckAgain),
            ),
          ),
        UpdateAvailable(:final release) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                leading: Icon(Icons.system_update,
                    color: theme.colorScheme.primary),
                title: Text(l10n.updateAvailable(release.version)),
                subtitle: Text(
                  release.apkSizeBytes > 0
                      ? l10n.updateDownloadSize(
                          _formatBytes(release.apkSizeBytes))
                      : l10n.updateTapToInstall,
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
                      child: Text(l10n.commonLater),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () =>
                          context.read<UpdateViewModel>().download(),
                      icon: const Icon(Icons.download),
                      label: Text(l10n.commonDownload),
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
                Text(l10n.updateDownloadingVersion(release.version),
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 6),
                Text(
                  progress == null
                      ? l10n.updateDownloading
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
            title: Text(l10n.updateReady(release.version)),
            subtitle: Text(l10n.updateReadySubtitle),
            trailing: FilledButton(
              onPressed: () => context.read<UpdateViewModel>().install(),
              child: Text(l10n.commonInstall),
            ),
          ),
        UpdateCheckError(:final message) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: Icon(Icons.error_outline, color: theme.colorScheme.error),
            title: Text(l10n.updateCheckFailed),
            subtitle: Text(message),
            trailing: TextButton(
              onPressed: () => context.read<UpdateViewModel>().checkNow(),
              child: Text(l10n.commonRetry),
            ),
          ),
        UpdateDownloadError(:final message) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: Icon(Icons.error_outline, color: theme.colorScheme.error),
            title: Text(l10n.updateDownloadFailed),
            subtitle: Text(message),
            trailing: TextButton(
              onPressed: () => context.read<UpdateViewModel>().download(),
              child: Text(l10n.commonRetry),
            ),
          ),
        UpdateInstallError(:final message) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: Icon(Icons.error_outline, color: theme.colorScheme.error),
            title: Text(l10n.updateInstallFailed),
            subtitle: Text(message),
            trailing: TextButton(
              onPressed: () => context.read<UpdateViewModel>().install(),
              child: Text(l10n.commonRetry),
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
