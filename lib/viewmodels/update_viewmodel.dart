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

/// A deliberate [UpdateViewModel.checkNow] failed. There is no known release
/// to retry with — retry means checking again.
class UpdateCheckError extends UpdateState {
  const UpdateCheckError(this.failure, {this.detail});
  final UpdateFailure failure;
  final String? detail;
}

/// [UpdateViewModel.download] failed partway through. [release] is retained
/// so retry re-downloads the same release rather than losing track of it.
class UpdateDownloadError extends UpdateState {
  const UpdateDownloadError(this.release, this.failure, {this.detail});
  final AppRelease release;
  final UpdateFailure failure;
  final String? detail;
}

/// [UpdateViewModel.install] failed to hand the APK to the installer.
/// [release] and [file] are retained so retry reuses the already-downloaded,
/// already-validated APK rather than re-downloading it.
class UpdateInstallError extends UpdateState {
  const UpdateInstallError(this.release, this.file, this.failure, {this.detail});
  final AppRelease release;
  final File file;
  final UpdateFailure failure;
  final String? detail;
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
  /// the badge on the Settings tab. A download or install error still means
  /// an update is pending (the release is known and retry is one tap away),
  /// so those keep the badge lit; a check error does not, since no release is
  /// known to be waiting.
  bool get updateAvailable =>
      _state is UpdateAvailable ||
      _state is UpdateDownloading ||
      _state is UpdateReadyToInstall ||
      _state is UpdateDownloadError ||
      _state is UpdateInstallError;

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
      _set(UpdateCheckError(e.failure, detail: e.detail));
    } catch (e) {
      _set(UpdateCheckError(UpdateFailure.unexpected, detail: '$e'));
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
  /// Runs from [UpdateAvailable] (the normal path) or [UpdateDownloadError]
  /// (retry after a failed download) — both carry the release to download.
  ///
  /// [UpdateService.downloadApk]'s `onProgress` fires once per network
  /// chunk — hundreds to low thousands of times for a multi-megabyte APK.
  /// When the total size is known, each call is throttled to at most one
  /// `notifyListeners()` per whole percentage point. When it is unknown
  /// (`percent` is null, so the UI shows an indeterminate bar that cannot
  /// benefit from percent-based throttling), it is instead throttled to at
  /// most one emission per 100ms. Either way the very last call (received >=
  /// total) always goes through, so a determinate bar reliably reaches 100%.
  Future<void> download() async {
    final AppRelease release;
    final current = _state;
    if (current is UpdateAvailable) {
      release = current.release;
    } else if (current is UpdateDownloadError) {
      release = current.release;
    } else {
      return;
    }

    _set(UpdateDownloading(release, 0, release.apkSizeBytes));
    int? lastEmittedPercent;
    DateTime? lastEmittedAt;
    try {
      final file = await _service.downloadApk(
        release,
        onProgress: (received, total) {
          final isFinal = total > 0 && received >= total;
          final percent = total > 0 ? (received * 100) ~/ total : null;
          if (!isFinal) {
            if (percent != null) {
              if (percent == lastEmittedPercent) return;
            } else {
              final now = DateTime.now();
              if (lastEmittedAt != null &&
                  now.difference(lastEmittedAt!) <
                      const Duration(milliseconds: 100)) {
                return;
              }
              lastEmittedAt = now;
            }
          }
          lastEmittedPercent = percent;
          _set(UpdateDownloading(release, received, total));
        },
      );
      _set(UpdateReadyToInstall(release, file));
    } on UpdateException catch (e) {
      _set(UpdateDownloadError(release, e.failure, detail: e.detail));
    } catch (e) {
      _set(UpdateDownloadError(release, UpdateFailure.unexpected,
          detail: '$e'));
    }
  }

  /// Hand the downloaded APK to the system installer.
  ///
  /// Runs from [UpdateReadyToInstall] (the normal path) or
  /// [UpdateInstallError] (retry after a failed install) — both carry the
  /// already-downloaded, already-validated file, so retrying here never
  /// re-downloads it.
  ///
  /// Deliberately does not delete [file] on success: the install intent is
  /// asynchronous, so Android may still be reading it when [installApk]
  /// returns. It is swept on the next launch instead — see
  /// [UpdateService.cleanUpDownloadedApks].
  Future<void> install() async {
    final AppRelease release;
    final File file;
    final current = _state;
    if (current is UpdateReadyToInstall) {
      release = current.release;
      file = current.file;
    } else if (current is UpdateInstallError) {
      release = current.release;
      file = current.file;
    } else {
      return;
    }
    try {
      await _service.installApk(file);
    } on UpdateException catch (e) {
      _set(UpdateInstallError(release, file, e.failure, detail: e.detail));
    } catch (e) {
      _set(UpdateInstallError(release, file, UpdateFailure.unexpected,
          detail: '$e'));
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

  /// Remove APKs left in the cache by a previous update's install hand-off.
  /// Safe to call on every launch; [UpdateService.cleanUpDownloadedApks]
  /// swallows every error itself.
  Future<void> cleanUpDownloadedApks() => _service.cleanUpDownloadedApks();

  /// Return to the resting state, e.g. after the user dismisses an error.
  void reset() => _set(const UpdateIdle());
}
