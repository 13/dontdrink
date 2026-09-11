import 'dart:io';

import 'package:dont_drink/core/models/app_release.dart';
import 'package:dont_drink/data/repositories/settings_repository.dart';
import 'package:dont_drink/services/update_service.dart';
import 'package:dont_drink/viewmodels/update_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

AppRelease _release(String version) => AppRelease(
      version: version,
      tagName: 'v$version',
      notes: 'notes',
      apkUrl: 'https://example.invalid/app.apk',
      apkSizeBytes: 1000,
    );

/// Records how many times the network was asked, and can fail on demand.
///
/// [downloadChunks] lets a test script exactly the sequence of
/// `onProgress(received, total)` calls `downloadApk` makes, against
/// [downloadTotal]. Defaults to the original two-call shape.
class _FakeService extends UpdateService {
  _FakeService({
    this.release,
    this.throwMessage,
    List<int>? downloadChunks,
    this.downloadTotal = 1000,
  }) : downloadChunks = downloadChunks ?? const [500, 1000];

  final AppRelease? release;
  final String? throwMessage;
  final List<int> downloadChunks;
  final int downloadTotal;
  int fetchCount = 0;

  @override
  Future<AppRelease?> fetchLatest() async {
    fetchCount++;
    if (throwMessage != null) throw UpdateException(throwMessage!);
    return release;
  }

  @override
  Future<File> downloadApk(
    AppRelease release, {
    void Function(int received, int total)? onProgress,
  }) async {
    for (final received in downloadChunks) {
      onProgress?.call(received, downloadTotal);
    }
    return File('/tmp/does-not-need-to-exist.apk');
  }

  @override
  Future<bool> installApk(File apk) async => true;
}

/// Fails the first `downloadApk` call, succeeds on every call after —
/// simulates retrying a failed download.
class _FlakyDownloadService extends UpdateService {
  _FlakyDownloadService({required this.release});

  final AppRelease release;
  int downloadCalls = 0;

  @override
  Future<AppRelease?> fetchLatest() async => release;

  @override
  Future<File> downloadApk(
    AppRelease release, {
    void Function(int received, int total)? onProgress,
  }) async {
    downloadCalls++;
    if (downloadCalls == 1) {
      throw const UpdateException(
          'The download ended early and the file is incomplete.');
    }
    onProgress?.call(1000, 1000);
    return File('/tmp/does-not-need-to-exist.apk');
  }

  @override
  Future<bool> installApk(File apk) async => true;
}

/// Fails every `installApk` call — simulates the installer never launching.
class _FailingInstallService extends UpdateService {
  _FailingInstallService({required this.release});

  final AppRelease release;

  @override
  Future<AppRelease?> fetchLatest() async => release;

  @override
  Future<File> downloadApk(
    AppRelease release, {
    void Function(int received, int total)? onProgress,
  }) async {
    onProgress?.call(1000, 1000);
    return File('/tmp/does-not-need-to-exist.apk');
  }

  @override
  Future<bool> installApk(File apk) async {
    throw const UpdateException('Could not open the installer: denied.');
  }
}

UpdateViewModel _vm(
  UpdateService service, {
  String current = '1.1.1',
}) =>
    UpdateViewModel(
      settings: SettingsRepository(),
      service: service,
      currentVersion: () async => current,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('checkNow', () {
    test('reports an available update when the release is newer', () async {
      final vm = _vm(_FakeService(release: _release('1.2.0')));
      await vm.checkNow();
      expect(vm.state, isA<UpdateAvailable>());
      expect((vm.state as UpdateAvailable).release.version, '1.2.0');
      expect(vm.updateAvailable, isTrue);
    });

    test('reports up to date when the release is the same version', () async {
      final vm = _vm(_FakeService(release: _release('1.1.1')));
      await vm.checkNow();
      expect(vm.state, isA<UpdateUpToDate>());
      expect(vm.updateAvailable, isFalse);
    });

    test('reports up to date when the release is older', () async {
      final vm = _vm(_FakeService(release: _release('1.0.0')));
      await vm.checkNow();
      expect(vm.state, isA<UpdateUpToDate>());
    });

    test('reports up to date when the release carries no apk', () async {
      final vm = _vm(_FakeService(release: null));
      await vm.checkNow();
      expect(vm.state, isA<UpdateUpToDate>());
    });

    test('surfaces a failure as UpdateCheckError, and it does not badge',
        () async {
      final vm = _vm(_FakeService(throwMessage: 'Could not reach GitHub.'));
      await vm.checkNow();
      expect(vm.state, isA<UpdateCheckError>());
      expect((vm.state as UpdateCheckError).message, 'Could not reach GitHub.');
      expect(vm.updateAvailable, isFalse,
          reason: 'a check error means no release is known to be pending');
    });

    test('ignores a skipped version — a manual check always reports', () async {
      final settings = SettingsRepository();
      await settings.setSkippedVersion('1.2.0');
      final vm = _vm(_FakeService(release: _release('1.2.0')));
      await vm.checkNow();
      expect(vm.state, isA<UpdateAvailable>(),
          reason: 'skipping suppresses silent checks, not deliberate ones');
    });

    test('records the check time', () async {
      final settings = SettingsRepository();
      expect(await settings.getLastUpdateCheck(), isNull);
      await _vm(_FakeService(release: _release('1.2.0'))).checkNow();
      expect(await settings.getLastUpdateCheck(), isNotNull);
    });
  });

  group('silentCheck throttle', () {
    test('checks when no check has ever run', () async {
      final service = _FakeService(release: _release('1.2.0'));
      final vm = _vm(service);
      await vm.silentCheck();
      expect(service.fetchCount, 1);
      expect(vm.state, isA<UpdateAvailable>());
    });

    test('does not check again within 24 hours', () async {
      await SettingsRepository()
          .setLastUpdateCheck(DateTime.now().subtract(const Duration(hours: 3)));
      final service = _FakeService(release: _release('1.2.0'));
      await _vm(service).silentCheck();
      expect(service.fetchCount, 0);
    });

    test('checks again after 24 hours have passed', () async {
      await SettingsRepository()
          .setLastUpdateCheck(DateTime.now().subtract(const Duration(hours: 25)));
      final service = _FakeService(release: _release('1.2.0'));
      await _vm(service).silentCheck();
      expect(service.fetchCount, 1);
    });
  });

  group('silentCheck behaviour', () {
    test('stays quiet for a version the user skipped', () async {
      await SettingsRepository().setSkippedVersion('1.2.0');
      final vm = _vm(_FakeService(release: _release('1.2.0')));
      await vm.silentCheck();
      expect(vm.state, isA<UpdateIdle>());
      expect(vm.updateAvailable, isFalse);
    });

    test('still surfaces a version newer than the skipped one', () async {
      await SettingsRepository().setSkippedVersion('1.2.0');
      final vm = _vm(_FakeService(release: _release('1.3.0')));
      await vm.silentCheck();
      expect(vm.state, isA<UpdateAvailable>());
    });

    test('swallows failures entirely — never shows an error on launch', () async {
      final vm = _vm(_FakeService(throwMessage: 'Could not reach GitHub.'));
      await vm.silentCheck();
      expect(vm.state, isA<UpdateIdle>(),
          reason: 'a failed silent check must be invisible');
    });
  });

  group('download and install', () {
    test('moves through downloading to ready, reporting progress', () async {
      final vm = _vm(_FakeService(release: _release('1.2.0')));
      await vm.checkNow();

      final seen = <double?>[];
      vm.addListener(() {
        final s = vm.state;
        if (s is UpdateDownloading) seen.add(s.progress);
      });

      await vm.download();
      expect(seen, isNotEmpty);
      expect(seen.last, 1.0);
      expect(vm.state, isA<UpdateReadyToInstall>());
    });

    test('download does nothing when no update is available', () async {
      final vm = _vm(_FakeService(release: null));
      await vm.checkNow();
      await vm.download();
      expect(vm.state, isA<UpdateUpToDate>());
    });

    test(
        'percent-based throttle collapses many same-percent chunks into few notifications',
        () async {
      // 10 chunks that all land on 50%, then the final chunk. Without
      // throttling this would be 11 UpdateDownloading notifications.
      final chunks = [for (var i = 500; i < 510; i++) i, 1000];
      final vm = _vm(_FakeService(
        release: _release('1.2.0'),
        downloadChunks: chunks,
        downloadTotal: 1000,
      ));
      await vm.checkNow();

      final seen = <double?>[];
      vm.addListener(() {
        final s = vm.state;
        if (s is UpdateDownloading) seen.add(s.progress);
      });

      await vm.download();
      expect(seen.length, lessThan(chunks.length),
          reason: 'same-percent chunks beyond the first must be throttled');
      expect(seen.last, 1.0);
      expect(vm.state, isA<UpdateReadyToInstall>());
    });

    test(
        'time-based throttle limits notifications when the total size is unknown',
        () async {
      // 20 chunks fired back-to-back with no known total: percent is always
      // null, so the throttle can only be time-based. Fired synchronously,
      // they land well inside one 100ms window.
      final chunks = [for (var i = 1; i <= 20; i++) i * 100];
      final vm = _vm(_FakeService(
        release: _release('1.2.0'),
        downloadChunks: chunks,
        downloadTotal: 0,
      ));
      await vm.checkNow();

      final seen = <double?>[];
      vm.addListener(() {
        final s = vm.state;
        if (s is UpdateDownloading) seen.add(s.progress);
      });

      await vm.download();
      expect(seen.length, lessThan(5),
          reason: 'a 100ms time throttle must not let every chunk through');
      expect(vm.state, isA<UpdateReadyToInstall>());
    });

    test('a failed download surfaces UpdateDownloadError and retains the release',
        () async {
      final service = _FlakyDownloadService(release: _release('1.2.0'));
      final vm = _vm(service);
      await vm.checkNow();

      await vm.download();
      expect(vm.state, isA<UpdateDownloadError>());
      expect((vm.state as UpdateDownloadError).release.version, '1.2.0');
      expect(vm.updateAvailable, isTrue,
          reason: 'a download error still means an update is pending');
    });

    test('download() retries from UpdateDownloadError and succeeds', () async {
      final service = _FlakyDownloadService(release: _release('1.2.0'));
      final vm = _vm(service);
      await vm.checkNow();
      await vm.download();
      expect(vm.state, isA<UpdateDownloadError>());

      await vm.download();
      expect(vm.state, isA<UpdateReadyToInstall>());
      expect(service.downloadCalls, 2);
    });

    test('a failed install surfaces UpdateInstallError and retains the file',
        () async {
      final service = _FailingInstallService(release: _release('1.2.0'));
      final vm = _vm(service);
      await vm.checkNow();
      await vm.download();
      expect(vm.state, isA<UpdateReadyToInstall>());

      await vm.install();
      expect(vm.state, isA<UpdateInstallError>());
      expect((vm.state as UpdateInstallError).release.version, '1.2.0');
      expect(vm.updateAvailable, isTrue,
          reason: 'an install error still means an update is pending');
    });

    test('install() does nothing from a state with no downloaded file',
        () async {
      final vm = _vm(_FakeService(release: _release('1.2.0')));
      await vm.checkNow();
      await vm.install();
      expect(vm.state, isA<UpdateAvailable>());
    });
  });

  group('skipAvailableVersion', () {
    test('records the version and returns to idle', () async {
      final vm = _vm(_FakeService(release: _release('1.2.0')));
      await vm.checkNow();
      await vm.skipAvailableVersion();

      expect(await SettingsRepository().getSkippedVersion(), '1.2.0');
      expect(vm.state, isA<UpdateIdle>());
    });
  });
}
