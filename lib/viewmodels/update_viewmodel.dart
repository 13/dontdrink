import 'dart:io';

import 'package:dont_drink/core/models/app_release.dart';
import 'package:dont_drink/data/repositories/settings_repository.dart';
import 'package:dont_drink/services/update_service.dart';
import 'package:flutter/foundation.dart';

/// What the updater is doing right now. One UI row per state.
sealed class UpdateState {
  const UpdateState();
}

class UpdateIdle extends UpdateState {
  const UpdateIdle();
}

class UpdateChecking extends UpdateState {
  const UpdateChecking();
}

class UpdateUpToDate extends UpdateState {
  const UpdateUpToDate(this.currentVersion);
  final String currentVersion;
}

class UpdateAvailable extends UpdateState {
  const UpdateAvailable(this.release);
  final AppRelease release;
}

class UpdateDownloading extends UpdateState {
  const UpdateDownloading(this.release, this.receivedBytes, this.totalBytes);

  final AppRelease release;
  final int receivedBytes;
  final int totalBytes;

  /// 0.0–1.0, or null when the total size is unknown (indeterminate bar).
  double? get progress =>
      totalBytes > 0 ? (receivedBytes / totalBytes).clamp(0.0, 1.0) : null;
}

class UpdateReadyToInstall extends UpdateState {
  const UpdateReadyToInstall(this.release, this.file);
  final AppRelease release;
  final File file;
}

class UpdateError extends UpdateState {
  const UpdateError(this.message);
  final String message;
}

/// Owns the updater's state, the once-per-day throttle on silent checks, and
/// the "Later" rule that keeps a dismissed version quiet.
class UpdateViewModel extends ChangeNotifier {
  UpdateViewModel({
    required SettingsRepository settings,
    required Future<String> Function() currentVersion,
    UpdateService? service,
    Duration silentCheckInterval = const Duration(hours: 24),
  })  : _settings = settings,
        _currentVersion = currentVersion,
        _service = service ?? UpdateService(),
        _silentCheckInterval = silentCheckInterval;

  final SettingsRepository _settings;
  final Future<String> Function() _currentVersion;
  final UpdateService _service;
  final Duration _silentCheckInterval;

  UpdateState _state = const UpdateIdle();
  UpdateState get state => _state;

  /// True when there is a newer release the user has been told about — drives
  /// the badge on the Settings tab.
  bool get updateAvailable =>
      _state is UpdateAvailable ||
      _state is UpdateDownloading ||
      _state is UpdateReadyToInstall;

  void _set(UpdateState next) {
    _state = next;
    notifyListeners();
  }

  /// A deliberate check. Always hits the network, always reports the outcome —
  /// including "you're up to date" and any failure — and ignores a previously
  /// skipped version, because the user asked.
  Future<void> checkNow() async {
    _set(const UpdateChecking());
    try {
      final release = await _service.fetchLatest();
      await _settings.setLastUpdateCheck(DateTime.now());
      final current = await _currentVersion();

      if (release == null || !isNewerVersion(release.version, current)) {
        _set(UpdateUpToDate(current));
        return;
      }
      _set(UpdateAvailable(release));
    } on UpdateException catch (e) {
      _set(UpdateError(e.message));
    } catch (e) {
      _set(UpdateError('Update check failed: $e'));
    }
  }

  /// The once-a-day check on launch. Throttled, respects a skipped version,
  /// and swallows every failure — it must never interrupt someone opening the
  /// app to log a day.
  Future<void> silentCheck() async {
    try {
      final last = await _settings.getLastUpdateCheck();
      if (last != null &&
          DateTime.now().difference(last) < _silentCheckInterval) {
        return;
      }

      final release = await _service.fetchLatest();
      await _settings.setLastUpdateCheck(DateTime.now());
      if (release == null) return;

      final current = await _currentVersion();
      if (!isNewerVersion(release.version, current)) return;

      final skipped = await _settings.getSkippedVersion();
      if (skipped != null && !isNewerVersion(release.version, skipped)) {
        return;
      }

      _set(UpdateAvailable(release));
    } catch (_) {
      // Deliberately silent: a background check that cannot reach GitHub is
      // not something to interrupt the user with.
    }
  }

  /// Download the available release's APK, reporting progress.
  ///
  /// [UpdateService.downloadApk]'s `onProgress` fires once per network
  /// chunk — hundreds to low thousands of times for a multi-megabyte APK.
  /// Each call is throttled to at most one `notifyListeners()` per whole
  /// percentage point, except the very last one (received >= total), which
  /// always goes through so the progress bar reliably reaches 100%.
  Future<void> download() async {
    final available = _state;
    if (available is! UpdateAvailable) return;

    _set(UpdateDownloading(available.release, 0, available.release.apkSizeBytes));
    int? lastEmittedPercent;
    try {
      final file = await _service.downloadApk(
        available.release,
        onProgress: (received, total) {
          final isFinal = total > 0 && received >= total;
          final percent = total > 0 ? (received * 100) ~/ total : null;
          if (!isFinal && percent != null && percent == lastEmittedPercent) {
            return;
          }
          lastEmittedPercent = percent;
          _set(UpdateDownloading(available.release, received, total));
        },
      );
      _set(UpdateReadyToInstall(available.release, file));
    } on UpdateException catch (e) {
      _set(UpdateError(e.message));
    } catch (e) {
      _set(UpdateError('Download failed: $e'));
    }
  }

  /// Hand the downloaded APK to the system installer.
  Future<void> install() async {
    final ready = _state;
    if (ready is! UpdateReadyToInstall) return;
    try {
      await _service.installApk(ready.file);
    } on UpdateException catch (e) {
      _set(UpdateError(e.message));
    } catch (e) {
      _set(UpdateError('Could not start the installer: $e'));
    }
  }

  /// "Later" — stay quiet about this version on silent checks until something
  /// newer appears. A manual check still reports it.
  Future<void> skipAvailableVersion() async {
    final available = _state;
    if (available is! UpdateAvailable) return;
    await _settings.setSkippedVersion(available.release.version);
    _set(const UpdateIdle());
  }

  /// Return to the resting state, e.g. after the user dismisses an error.
  void reset() => _set(const UpdateIdle());
}
