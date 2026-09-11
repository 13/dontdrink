# In-App Updater Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the app check GitHub Releases for a newer version, download the APK with visible progress, and hand it to Android's package installer.

**Architecture:** A pure `AppRelease` model plus a numeric version comparison (the part most likely to be silently wrong, and fully unit-testable) sits under an `UpdateService` that does the two network calls with `dart:io`'s `HttpClient`. `UpdateViewModel` holds a sealed `UpdateState` machine and owns the 24-hour throttle and the "skip this version" rule. The UI is one card in Settings, hidden entirely on iOS.

**Tech Stack:** Flutter / Dart 3.13.2, `provider` (MVVM), `shared_preferences`, `package_info_plus` (already present), `dart:io` `HttpClient` for networking, and one new runtime dependency — `open_filex` — to hand the APK to the system installer.

**Spec:** `docs/superpowers/specs/2026-09-11-in-app-updater-design.md`

## Global Constraints

- **Flutter is not on PATH.** Every command in this plan needs `export PATH="$HOME/flutter/bin:$PATH"` first. The installed SDK is Dart 3.13.2. `fvm` is not installed; plain `flutter` is correct.
- **`flutter analyze` must report "No issues found" at the end of every task.** The project uses `flutter_lints ^6.0.0`.
- **`flutter build apk` cannot be run on this machine.** Only Java 25 is installed and Gradle 8.14 requires 17 or 21. Report the error if you try; never treat it as a code defect.
- **The repository is `13/dontdrink`, public.** The releases API needs no authentication token. Never add one.
- **Only one new runtime dependency: `open_filex`.** Everything else uses what is already in `pubspec.yaml`.
- **The four media permissions `open_filex` declares must be stripped.** This app's value proposition is privacy; silently gaining "Photos and videos" access is a regression.
- **Version comparison is numeric, component by component** — never string comparison, which sorts `1.10.0` below `1.9.0`.
- **Compare the semver `version`, never the build number.** Build numbers come from `github.run_number` and are not comparable across re-runs.
- **A failed *silent* check is swallowed entirely.** It must never produce a dialog, snackbar, or visible error on launch. Only a *manual* check reports failure.
- **The app's identity does not change.** App name, launcher icon, `MaterialApp.title` and the About card heading stay "Don't Drink".
- **The data-privacy claim stays true and must keep being stated.** No tracking data ever leaves the device; the only outbound requests are to `api.github.com` and `objects.githubusercontent.com`.

---

## File Structure

**Created:**

| File | Responsibility |
|---|---|
| `lib/core/models/app_release.dart` | `AppRelease` value object, GitHub JSON parsing, numeric version comparison |
| `lib/services/update_service.dart` | `UpdateException`, the two network calls, the install hand-off |
| `lib/viewmodels/update_viewmodel.dart` | `UpdateState` sealed hierarchy + throttle and skip rules |
| `lib/ui/settings/widgets/update_section.dart` | The Settings ▸ Updates card, one row per state |
| `android/app/src/main/res/xml/file_paths.xml` | Cache-path entry so the installer can read the downloaded APK |
| `test/app_release_test.dart` | Version comparison + release parsing |
| `test/update_viewmodel_test.dart` | Throttle, skip, state transitions |

**Modified:** `pubspec.yaml`, `android/app/src/main/AndroidManifest.xml`, `lib/data/repositories/settings_repository.dart`, `lib/ui/settings/settings_screen.dart`, `lib/ui/shell/home_shell.dart`, `lib/main.dart`, `README.md`.

---

### Task 1: AppRelease and numeric version comparison

**Files:**
- Create: `lib/core/models/app_release.dart`
- Test: `test/app_release_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `class AppRelease` with `const AppRelease({required String version, required String tagName, required String notes, required String apkUrl, required int apkSizeBytes, DateTime? publishedAt})`.
  - `static AppRelease? AppRelease.fromGitHubJson(Map<String, dynamic> json)` — returns null when the payload has no usable APK asset or no tag.
  - `String normalizeVersion(String raw)` — strips a leading `v` and surrounding whitespace.
  - `int compareVersions(String a, String b)` — negative / zero / positive.
  - `bool isNewerVersion(String candidate, String current)`.

- [ ] **Step 1: Write the failing test**

Create `test/app_release_test.dart`:

```dart
import 'package:dont_drink/core/models/app_release.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeVersion', () {
    test('strips a leading v and whitespace', () {
      expect(normalizeVersion('v1.2.3'), '1.2.3');
      expect(normalizeVersion('  v1.2.3 '), '1.2.3');
      expect(normalizeVersion('1.2.3'), '1.2.3');
    });
  });

  group('compareVersions', () {
    test('compares numerically, not lexically', () {
      // The whole reason this function exists: string comparison puts
      // '1.10.0' below '1.9.0'.
      expect(compareVersions('1.10.0', '1.9.0'), greaterThan(0));
      expect(compareVersions('1.9.0', '1.10.0'), lessThan(0));
    });

    test('treats missing components as zero', () {
      expect(compareVersions('1.2', '1.2.0'), 0);
      expect(compareVersions('1.2.1', '1.2'), greaterThan(0));
    });

    test('returns zero for equal versions', () {
      expect(compareVersions('2.0.0', '2.0.0'), 0);
    });

    test('ignores a v prefix on either side', () {
      expect(compareVersions('v1.3.0', '1.2.0'), greaterThan(0));
      expect(compareVersions('1.3.0', 'v1.3.0'), 0);
    });

    test('treats non-numeric components as zero rather than throwing', () {
      expect(compareVersions('1.2.beta', '1.2.0'), 0);
      expect(compareVersions('garbage', '0.0.0'), 0);
    });

    test('compares major before minor before patch', () {
      expect(compareVersions('2.0.0', '1.99.99'), greaterThan(0));
      expect(compareVersions('1.3.0', '1.2.99'), greaterThan(0));
    });
  });

  group('isNewerVersion', () {
    test('is true only when strictly greater', () {
      expect(isNewerVersion('1.2.0', '1.1.1'), isTrue);
      expect(isNewerVersion('1.1.1', '1.1.1'), isFalse);
      expect(isNewerVersion('1.1.0', '1.1.1'), isFalse);
    });
  });

  group('AppRelease.fromGitHubJson', () {
    Map<String, dynamic> payload({
      String tag = 'v1.2.0',
      List<Map<String, dynamic>>? assets,
    }) =>
        {
          'tag_name': tag,
          'body': 'Release notes here.',
          'published_at': '2026-06-09T11:17:54Z',
          'assets': assets ??
              [
                {
                  'name': 'dont-drink-v1.2.0.apk',
                  'browser_download_url':
                      'https://example.invalid/dont-drink-v1.2.0.apk',
                  'size': 12345678,
                },
              ],
        };

    test('parses tag, notes, asset url and size', () {
      final release = AppRelease.fromGitHubJson(payload())!;
      expect(release.tagName, 'v1.2.0');
      expect(release.version, '1.2.0');
      expect(release.notes, 'Release notes here.');
      expect(release.apkUrl, 'https://example.invalid/dont-drink-v1.2.0.apk');
      expect(release.apkSizeBytes, 12345678);
      expect(release.publishedAt?.year, 2026);
    });

    test('returns null when the release carries no apk asset', () {
      final json = payload(assets: [
        {
          'name': 'source.zip',
          'browser_download_url': 'https://example.invalid/source.zip',
          'size': 42,
        },
      ]);
      expect(AppRelease.fromGitHubJson(json), isNull);
    });

    test('returns null when assets is empty or missing', () {
      expect(AppRelease.fromGitHubJson(payload(assets: [])), isNull);
      expect(AppRelease.fromGitHubJson({'tag_name': 'v1.0.0'}), isNull);
    });

    test('returns null when tag_name is missing or not a string', () {
      final json = payload();
      json.remove('tag_name');
      expect(AppRelease.fromGitHubJson(json), isNull);

      final numericTag = payload();
      numericTag['tag_name'] = 12;
      expect(AppRelease.fromGitHubJson(numericTag), isNull);
    });

    test('tolerates a missing body, size or published_at', () {
      final json = payload();
      json.remove('body');
      json.remove('published_at');
      (json['assets'] as List).first as Map<String, dynamic>
        ..remove('size');

      final release = AppRelease.fromGitHubJson(json)!;
      expect(release.notes, isEmpty);
      expect(release.apkSizeBytes, 0);
      expect(release.publishedAt, isNull);
    });

    test('picks the apk when several assets are present', () {
      final json = payload(assets: [
        {
          'name': 'checksums.txt',
          'browser_download_url': 'https://example.invalid/checksums.txt',
          'size': 100,
        },
        {
          'name': 'dont-drink-v1.2.0.apk',
          'browser_download_url': 'https://example.invalid/app.apk',
          'size': 200,
        },
      ]);
      expect(AppRelease.fromGitHubJson(json)!.apkUrl,
          'https://example.invalid/app.apk');
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter test test/app_release_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:dont_drink/core/models/app_release.dart'`.

- [ ] **Step 3: Write `lib/core/models/app_release.dart`**

```dart
import 'package:flutter/foundation.dart';

/// A published GitHub release that carries an installable APK.
@immutable
class AppRelease {
  const AppRelease({
    required this.version,
    required this.tagName,
    required this.notes,
    required this.apkUrl,
    required this.apkSizeBytes,
    this.publishedAt,
  });

  /// Semver string with no leading `v`, e.g. `1.2.0`.
  final String version;

  /// The git tag as published, e.g. `v1.2.0`.
  final String tagName;

  /// Release notes body. Empty when the release has none.
  final String notes;

  final String apkUrl;

  /// Size in bytes, or 0 when GitHub did not report one.
  final int apkSizeBytes;

  final DateTime? publishedAt;

  /// Build a release from the `releases/latest` payload.
  ///
  /// Returns null — rather than throwing — when the payload has no tag or no
  /// APK asset. Both are legitimate states (a release published with no
  /// artifact yet), not errors worth surfacing to the user.
  static AppRelease? fromGitHubJson(Map<String, dynamic> json) {
    final tag = json['tag_name'];
    if (tag is! String || tag.isEmpty) return null;

    final assets = json['assets'];
    if (assets is! List) return null;

    Map<String, dynamic>? apk;
    for (final asset in assets) {
      if (asset is! Map) continue;
      final name = asset['name'];
      if (name is String && name.toLowerCase().endsWith('.apk')) {
        apk = Map<String, dynamic>.from(asset);
        break;
      }
    }
    if (apk == null) return null;

    final url = apk['browser_download_url'];
    if (url is! String || url.isEmpty) return null;

    final size = apk['size'];
    final body = json['body'];
    final published = json['published_at'];

    return AppRelease(
      version: normalizeVersion(tag),
      tagName: tag,
      notes: body is String ? body : '',
      apkUrl: url,
      apkSizeBytes: size is int ? size : 0,
      publishedAt: published is String ? DateTime.tryParse(published) : null,
    );
  }
}

/// Strip a leading `v` and surrounding whitespace from a tag or version.
String normalizeVersion(String raw) {
  final trimmed = raw.trim();
  if (trimmed.startsWith('v') || trimmed.startsWith('V')) {
    return trimmed.substring(1);
  }
  return trimmed;
}

/// Compare two version strings numerically, component by component.
///
/// Negative when [a] is older, zero when equal, positive when [a] is newer.
/// Missing components count as zero, so `1.2` equals `1.2.0`. A component that
/// is not a number counts as zero rather than throwing — a malformed tag
/// should never crash the updater, it should simply not look newer.
///
/// String comparison is deliberately NOT used: it sorts `1.10.0` below
/// `1.9.0`.
int compareVersions(String a, String b) {
  final left = normalizeVersion(a).split('.');
  final right = normalizeVersion(b).split('.');
  final length = left.length > right.length ? left.length : right.length;

  for (var i = 0; i < length; i++) {
    final l = i < left.length ? (int.tryParse(left[i]) ?? 0) : 0;
    final r = i < right.length ? (int.tryParse(right[i]) ?? 0) : 0;
    if (l != r) return l - r;
  }
  return 0;
}

/// True when [candidate] is strictly newer than [current].
bool isNewerVersion(String candidate, String current) =>
    compareVersions(candidate, current) > 0;
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/app_release_test.dart`
Expected: PASS — 14 tests.

- [ ] **Step 5: Run the full suite and analysis**

Run: `flutter test && flutter analyze`
Expected: all pass (74 existing + 14 new = 88), `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/core/models/app_release.dart test/app_release_test.dart
git commit -m "feat: add AppRelease model and numeric version comparison"
```

---

### Task 2: Update preferences — throttle timestamp and skipped version

**Files:**
- Modify: `lib/data/repositories/settings_repository.dart`
- Test: `test/settings_repository_update_test.dart` (new)

**Interfaces:**
- Consumes: nothing new.
- Produces, on `SettingsRepository`:
  - `Future<DateTime?> getLastUpdateCheck()`
  - `Future<void> setLastUpdateCheck(DateTime when)`
  - `Future<String?> getSkippedVersion()`
  - `Future<void> setSkippedVersion(String version)`
  - `Future<void> clearSkippedVersion()`

- [ ] **Step 1: Write the failing test**

Create `test/settings_repository_update_test.dart`:

```dart
import 'package:dont_drink/data/repositories/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('last update check is null before any check', () async {
    expect(await SettingsRepository().getLastUpdateCheck(), isNull);
  });

  test('last update check round-trips to the second', () async {
    final repo = SettingsRepository();
    final when = DateTime.fromMillisecondsSinceEpoch(1750000000000);
    await repo.setLastUpdateCheck(when);
    expect(await repo.getLastUpdateCheck(), when);
  });

  test('skipped version is null by default and round-trips', () async {
    final repo = SettingsRepository();
    expect(await repo.getSkippedVersion(), isNull);
    await repo.setSkippedVersion('1.2.0');
    expect(await repo.getSkippedVersion(), '1.2.0');
  });

  test('clearing the skipped version removes it', () async {
    final repo = SettingsRepository();
    await repo.setSkippedVersion('1.2.0');
    await repo.clearSkippedVersion();
    expect(await repo.getSkippedVersion(), isNull);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/settings_repository_update_test.dart`
Expected: FAIL — `The method 'getLastUpdateCheck' isn't defined for the type 'SettingsRepository'`.

- [ ] **Step 3: Add the five methods**

In `lib/data/repositories/settings_repository.dart`, add two key constants beside the existing ones:

```dart
  static const _kLastUpdateCheck = 'last_update_check';
  static const _kSkippedVersion = 'skipped_version';
```

and append these methods before the closing brace:

```dart
  // ── Updater ──────────────────────────────────────────────────────────────

  /// When the app last asked GitHub for a release, or null if never.
  /// Drives the once-per-24h throttle on the silent launch check.
  Future<DateTime?> getLastUpdateCheck() async {
    final prefs = await _p;
    final millis = prefs.getInt(_kLastUpdateCheck);
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  Future<void> setLastUpdateCheck(DateTime when) async {
    final prefs = await _p;
    await prefs.setInt(_kLastUpdateCheck, when.millisecondsSinceEpoch);
  }

  /// A version the user dismissed with "Later". Silent checks stay quiet for
  /// this version but still surface anything newer.
  Future<String?> getSkippedVersion() async {
    final prefs = await _p;
    return prefs.getString(_kSkippedVersion);
  }

  Future<void> setSkippedVersion(String version) async {
    final prefs = await _p;
    await prefs.setString(_kSkippedVersion, version);
  }

  Future<void> clearSkippedVersion() async {
    final prefs = await _p;
    await prefs.remove(_kSkippedVersion);
  }
```

Also update the class doc comment, which currently says "(theme, notifications)":

```dart
/// Persists lightweight user preferences (theme, notifications, updater
/// state) in [SharedPreferences]. No personal data, no account.
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/settings_repository_update_test.dart`
Expected: PASS — 4 tests.

- [ ] **Step 5: Run the full suite and analysis**

Run: `flutter test && flutter analyze`
Expected: 92 tests pass, `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/data/repositories/settings_repository.dart test/settings_repository_update_test.dart
git commit -m "feat: persist update-check timestamp and skipped version"
```

---

### Task 3: Android permissions and the install dependency

**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Create: `android/app/src/main/res/xml/file_paths.xml`

**Interfaces:**
- Produces: `open_filex` available to import; `INTERNET` and `REQUEST_INSTALL_PACKAGES` declared.

**Why the permission removals matter.** `open_filex` declares `READ_EXTERNAL_STORAGE`, `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO` and `READ_MEDIA_AUDIO` in its own manifest, and Android's manifest merger folds a library's permissions into the host app. This app only ever opens an APK it just wrote to its *own* cache directory, which needs none of them — and an app whose About card promises privacy should not start asking for photo access. `tools:node="remove"` is the supported way to drop a merged permission.

- [ ] **Step 1: Add the dependency**

In `pubspec.yaml`, under `dependencies:`, after the `share_plus` / `file_picker` block:

```yaml
  # Hands a downloaded APK to Android's package installer. Ships its own
  # FileProvider, so we must NOT declare a second one.
  open_filex: ^4.7.0
```

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter pub get`

> **Then check `android/local.properties`** — confirm `sdk.dir` still reads `/home/ben/Android/Sdk`. `pub get` is known to rewrite it to `/opt/android-sdk`, which has no NDK and no accepted licenses. Set it back if it changed.

- [ ] **Step 2: Rewrite the manifest's permission block**

In `android/app/src/main/AndroidManifest.xml`, add the `tools` namespace to the root element:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">
```

and replace the existing permission block (currently two `uses-permission` lines preceded by a comment claiming the app is fully offline) with:

```xml
    <!-- Local daily-reminder notifications. -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

    <!-- The in-app updater: fetch the latest release from api.github.com and
         hand the downloaded APK to the system installer. No tracking data
         ever leaves the device. -->
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES"/>

    <!-- open_filex declares these for its general file-opening use. We only
         ever open an APK from our own cache directory, so strip them rather
         than let the manifest merger add photo and media access to an app
         that promises none. -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
        tools:node="remove"/>
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"
        tools:node="remove"/>
    <uses-permission android:name="android.permission.READ_MEDIA_VIDEO"
        tools:node="remove"/>
    <uses-permission android:name="android.permission.READ_MEDIA_AUDIO"
        tools:node="remove"/>
```

- [ ] **Step 3: Create the file-paths resource**

Create `android/app/src/main/res/xml/file_paths.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<!-- Grants the system package installer read access to the APK we download
     into the app's own cache directory. open_filex provides the FileProvider
     that consumes this. -->
<paths>
    <cache-path name="cache" path="."/>
    <external-cache-path name="external_cache" path="."/>
</paths>
```

- [ ] **Step 4: Verify what can be verified here**

Run: `flutter analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: all tests pass (adding a dependency must not change behaviour).

Confirm the XML is well-formed:

```bash
python3 -c "import xml.dom.minidom,sys; [xml.dom.minidom.parse(p) for p in ['android/app/src/main/AndroidManifest.xml','android/app/src/main/res/xml/file_paths.xml']]; print('both parse OK')"
```

> **This task cannot be fully verified on this machine.** `flutter build apk` fails here for an unrelated Java-version reason, so the *merged* manifest — the thing that proves the permission removals worked — cannot be inspected. Say so plainly in your report. The branch owner will verify with:
> ```
> flutter build apk --debug
> ~/Android/Sdk/build-tools/<version>/aapt2 dump permissions build/app/outputs/flutter-apk/app-debug.apk
> ```
> expecting `INTERNET` and `REQUEST_INSTALL_PACKAGES` present, and no `READ_MEDIA_*` or `READ_EXTERNAL_STORAGE`.

- [ ] **Step 5: Commit**

```bash
git add pubspec.yaml pubspec.lock android/app/src/main/AndroidManifest.xml android/app/src/main/res/xml/file_paths.xml
git commit -m "feat: declare updater permissions and strip open_filex's media access"
```

---

### Task 4: UpdateService — fetch, download, install

**Files:**
- Create: `lib/services/update_service.dart`

**Interfaces:**
- Consumes: `AppRelease`, `AppRelease.fromGitHubJson` (Task 1); `open_filex` (Task 3).
- Produces:
  - `class UpdateException implements Exception` with `final String message` and a `toString()` returning it.
  - `class UpdateService` with:
    - `UpdateService({String owner = '13', String repo = 'dontdrink', HttpClient Function()? httpClientFactory})`
    - `Future<AppRelease?> fetchLatest()` — throws `UpdateException` on network or protocol failure; returns null when the latest release has no APK.
    - `Future<File> downloadApk(AppRelease release, {void Function(int received, int total)? onProgress})`
    - `Future<bool> installApk(File apk)` — true when the installer was launched.

**Why the methods are not final/private:** `UpdateViewModel`'s tests subclass `UpdateService` to avoid real network calls. Keep the class and its methods overridable.

- [ ] **Step 1: Write `lib/services/update_service.dart`**

```dart
import 'dart:convert';
import 'dart:io';

import 'package:dont_drink/core/models/app_release.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

/// A failure the user should be told about, phrased for display.
class UpdateException implements Exception {
  const UpdateException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Talks to GitHub Releases and hands a downloaded APK to the system
/// installer.
///
/// Uses `dart:io`'s [HttpClient] rather than adding a networking package: it
/// streams responses, which is what a determinate progress bar needs, and it
/// keeps the dependency count flat.
class UpdateService {
  UpdateService({
    this.owner = '13',
    this.repo = 'dontdrink',
    HttpClient Function()? httpClientFactory,
  }) : _httpClientFactory = httpClientFactory;

  final String owner;
  final String repo;
  final HttpClient Function()? _httpClientFactory;

  /// GitHub rejects API requests without a User-Agent.
  static const _userAgent = 'dont-drink-app';

  HttpClient _newClient() => (_httpClientFactory ?? HttpClient.new)();

  Uri get _latestReleaseUri =>
      Uri.https('api.github.com', '/repos/$owner/$repo/releases/latest');

  /// The latest published release, or null when it carries no APK asset.
  ///
  /// Throws [UpdateException] for anything the user should see: no network,
  /// a non-200 response, or a body that is not the JSON object we expect.
  Future<AppRelease?> fetchLatest() async {
    final client = _newClient();
    try {
      final request = await client.getUrl(_latestReleaseUri);
      request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
      request.headers.set(HttpHeaders.userAgentHeader, _userAgent);
      final response = await request.close();

      final body = await response.transform(utf8.decoder).join();

      if (response.statusCode == 404) {
        throw const UpdateException('No releases have been published yet.');
      }
      if (response.statusCode == 403) {
        // Unauthenticated API access is rate-limited to 60/hour per IP.
        throw const UpdateException(
            'GitHub is rate-limiting update checks. Try again later.');
      }
      if (response.statusCode != 200) {
        throw UpdateException(
            'GitHub returned ${response.statusCode} when checking for updates.');
      }

      final Object? decoded;
      try {
        decoded = jsonDecode(body);
      } on FormatException {
        throw const UpdateException(
            'GitHub returned something that was not valid JSON.');
      }
      if (decoded is! Map<String, dynamic>) {
        throw const UpdateException(
            'GitHub returned an unexpected response shape.');
      }

      return AppRelease.fromGitHubJson(decoded);
    } on SocketException {
      throw const UpdateException(
          'Could not reach GitHub. Check your connection.');
    } on HandshakeException {
      throw const UpdateException('Could not establish a secure connection.');
    } finally {
      client.close();
    }
  }

  /// Download [release]'s APK into the app's cache directory.
  ///
  /// [onProgress] receives bytes so far and the total. The total is the
  /// asset size GitHub reported, falling back to `content-length`; it is 0
  /// when neither is known, which the UI renders as indeterminate.
  Future<File> downloadApk(
    AppRelease release, {
    void Function(int received, int total)? onProgress,
  }) async {
    final client = _newClient();
    try {
      final request = await client.getUrl(Uri.parse(release.apkUrl));
      request.headers.set(HttpHeaders.userAgentHeader, _userAgent);
      final response = await request.close();

      if (response.statusCode != 200) {
        throw UpdateException(
            'Download failed with status ${response.statusCode}.');
      }

      final total = release.apkSizeBytes > 0
          ? release.apkSizeBytes
          : (response.contentLength > 0 ? response.contentLength : 0);

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/dont-drink-${release.tagName}.apk');
      // A half-written file from an interrupted attempt must not be installed.
      if (file.existsSync()) await file.delete();

      final sink = file.openWrite();
      var received = 0;
      try {
        await for (final chunk in response) {
          sink.add(chunk);
          received += chunk.length;
          onProgress?.call(received, total);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }

      return file;
    } on SocketException {
      throw const UpdateException(
          'The download was interrupted. Check your connection.');
    } finally {
      client.close();
    }
  }

  /// Hand [apk] to Android's package installer.
  ///
  /// Returns true when the installer was launched. On Android 8+ the
  /// "install unknown apps" permission is granted per-app at runtime; when it
  /// has not been granted the system opens that settings screen instead of
  /// installing, which is the correct behaviour and still counts as launched.
  Future<bool> installApk(File apk) async {
    final result = await OpenFilex.open(
      apk.path,
      type: 'application/vnd.android.package-archive',
    );
    if (result.type == ResultType.done) return true;
    throw UpdateException('Could not open the installer: ${result.message}');
  }
}
```

- [ ] **Step 2: Verify it compiles and nothing regressed**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: 92 tests pass.

> This task has no unit tests by design. `fetchLatest`'s parsing is already covered by Task 1's `AppRelease.fromGitHubJson` tests; what remains is real socket I/O and a platform channel, which the spec assigns to manual verification. Do not write a test that mocks `HttpClient` end to end just to have one — it would assert that your mock behaves like your mock. Say in your report that this task is covered by Task 1's tests plus manual verification.

- [ ] **Step 3: Commit**

```bash
git add lib/services/update_service.dart
git commit -m "feat: add UpdateService for release fetch, download and install"
```

---

### Task 5: UpdateState and UpdateViewModel

**Files:**
- Create: `lib/viewmodels/update_viewmodel.dart`
- Test: `test/update_viewmodel_test.dart`

**Interfaces:**
- Consumes: `AppRelease`, `isNewerVersion` (Task 1); `SettingsRepository`'s five updater methods (Task 2); `UpdateService`, `UpdateException` (Task 4).
- Produces:
  - `sealed class UpdateState` with `UpdateIdle`, `UpdateChecking`, `UpdateUpToDate(String currentVersion)`, `UpdateAvailable(AppRelease release)`, `UpdateDownloading(AppRelease release, int receivedBytes, int totalBytes)` (with `double? get progress`), `UpdateReadyToInstall(AppRelease release, File file)`, `UpdateError(String message)`.
  - `class UpdateViewModel extends ChangeNotifier` with `UpdateState get state`, `bool get updateAvailable`, `Future<void> checkNow()`, `Future<void> silentCheck()`, `Future<void> download()`, `Future<void> install()`, `Future<void> skipAvailableVersion()`.

- [ ] **Step 1: Write the failing test**

Create `test/update_viewmodel_test.dart`:

```dart
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
class _FakeService extends UpdateService {
  _FakeService({this.release, this.throwMessage});

  final AppRelease? release;
  final String? throwMessage;
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
    onProgress?.call(500, 1000);
    onProgress?.call(1000, 1000);
    return File('/tmp/does-not-need-to-exist.apk');
  }

  @override
  Future<bool> installApk(File apk) async => true;
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

    test('surfaces a failure as UpdateError', () async {
      final vm = _vm(_FakeService(throwMessage: 'Could not reach GitHub.'));
      await vm.checkNow();
      expect(vm.state, isA<UpdateError>());
      expect((vm.state as UpdateError).message, 'Could not reach GitHub.');
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
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/update_viewmodel_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:dont_drink/viewmodels/update_viewmodel.dart'`.

- [ ] **Step 3: Write `lib/viewmodels/update_viewmodel.dart`**

```dart
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
  Future<void> download() async {
    final available = _state;
    if (available is! UpdateAvailable) return;

    _set(UpdateDownloading(available.release, 0, available.release.apkSizeBytes));
    try {
      final file = await _service.downloadApk(
        available.release,
        onProgress: (received, total) {
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
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/update_viewmodel_test.dart`
Expected: PASS — 16 tests.

- [ ] **Step 5: Run the full suite and analysis**

Run: `flutter test && flutter analyze`
Expected: 108 tests pass, `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/viewmodels/update_viewmodel.dart test/update_viewmodel_test.dart
git commit -m "feat: add UpdateViewModel with daily throttle and skip-version rule"
```

---

### Task 6: The Settings ▸ Updates card

**Files:**
- Create: `lib/ui/settings/widgets/update_section.dart`
- Modify: `lib/ui/settings/settings_screen.dart`

**Interfaces:**
- Consumes: `UpdateViewModel` and every `UpdateState` subclass (Task 5), via `context.watch<UpdateViewModel>()`.
- Produces: `class UpdateSection extends StatelessWidget` — takes no arguments, returns `SizedBox.shrink()` on non-Android platforms.

**Platform guard.** The updater is Android-only: sideloading an IPA this way is not possible, so on iOS the whole section is hidden rather than shown disabled. A dead control is worse than no control.

- [ ] **Step 1: Write `lib/ui/settings/widgets/update_section.dart`**

```dart
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
```

- [ ] **Step 2: Add the section to the Settings screen**

In `lib/ui/settings/settings_screen.dart`, import the new widget and insert a section between `Data` and `About` — so it sits directly above the version number it relates to:

```dart
            const SizedBox(height: 24),
            const SectionHeader('Updates'),
            const UpdateSection(),
            const SizedBox(height: 24),
            const SectionHeader('About'),
```

On iOS `UpdateSection` renders nothing, which would leave a stray "Updates" header. Guard the header too — wrap both in a conditional so neither appears:

```dart
            if (Platform.isAndroid) ...[
              const SizedBox(height: 24),
              const SectionHeader('Updates'),
              const UpdateSection(),
            ],
```

Add `import 'dart:io' show Platform;` at the top of `settings_screen.dart`.

- [ ] **Step 3: Verify**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter analyze`
Expected: `No issues found!` — in particular, the `switch` expression over `UpdateState` must be exhaustive. If the analyzer reports a non-exhaustive switch, a state is missing; add it rather than adding a default case, so a future state cannot be silently unhandled.

Run: `flutter test`
Expected: 108 tests pass.

> You cannot run the app (headless, and the project targets only `android/` and `ios/`). State plainly in your report that the card's layout and each state's appearance are unverified.

- [ ] **Step 4: Commit**

```bash
git add lib/ui/settings/widgets/update_section.dart lib/ui/settings/settings_screen.dart
git commit -m "feat: add the Settings updates card"
```

---

### Task 7: Wire it up, badge the tab, and correct the offline copy

**Files:**
- Modify: `lib/main.dart`
- Modify: `lib/ui/shell/home_shell.dart`
- Modify: `lib/ui/settings/settings_screen.dart` (About card copy)
- Modify: `README.md`

**Interfaces:**
- Consumes: `UpdateViewModel` (Task 5).
- Produces: `UpdateViewModel` provided app-wide; a silent check fired after first frame; corrected user-facing copy.

**The copy is not optional.** The app currently tells the user, in two places, that it is "fully offline" and declares no network permission. After this feature both statements are false. The *data* claim stays true — no tracking data leaves the device — and must keep being said, because it is the thing users actually care about. Saying something false about privacy is worse than saying nothing.

- [ ] **Step 1: Provide the view model and fire the silent check**

In `lib/main.dart`, add imports:

```dart
import 'dart:async' show unawaited;

import 'package:dont_drink/viewmodels/update_viewmodel.dart';
import 'package:package_info_plus/package_info_plus.dart';
```

Inside the existing `try` block, after `modeViewModel` is built and before `runApp`:

```dart
    final updateViewModel = UpdateViewModel(
      settings: settingsRepository,
      currentVersion: () async =>
          (await PackageInfo.fromPlatform()).version,
    );
```

This needs `settingsRepository` to be a named local. The current code constructs `SettingsRepository()` inline inside `SettingsViewModel(repository: SettingsRepository())`; hoist it so both view models share one instance:

```dart
    final settingsRepository = SettingsRepository();
    final settingsViewModel =
        SettingsViewModel(repository: settingsRepository);
```

Add the provider to the existing `MultiProvider` list:

```dart
          ChangeNotifierProvider.value(value: updateViewModel),
```

Then, immediately after the `runApp(...)` call and still inside the `try`:

```dart
    // Once-a-day check for a newer release, after the first frame. Deliberately
    // not awaited and deliberately silent: it must never delay startup or
    // interrupt someone opening the app to log a day.
    unawaited(updateViewModel.silentCheck());
```

- [ ] **Step 2: Badge the Settings tab**

In `lib/ui/shell/home_shell.dart`, import `provider` and the view model, then make the Settings destination's icon carry a dot when an update is waiting. Replace the Settings `NavigationDestination` with:

```dart
          NavigationDestination(
            icon: _MaybeBadged(child: const Icon(Icons.settings_outlined)),
            selectedIcon: _MaybeBadged(child: const Icon(Icons.settings)),
            label: 'Settings',
          ),
```

`_tabs` is `static const`, but the destinations list is built in `build`, so it can read context. If the destinations are currently inside a `const [...]` literal, remove that `const`.

Add this private widget at the bottom of the file:

```dart
/// Wraps [child] in a small dot when an update is waiting, so the Settings tab
/// advertises it without a dialog.
class _MaybeBadged extends StatelessWidget {
  const _MaybeBadged({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final showDot =
        context.select<UpdateViewModel, bool>((vm) => vm.updateAvailable);
    if (!showDot) return child;
    return Badge(child: child);
  }
}
```

- [ ] **Step 3: Correct the About card**

In `lib/ui/settings/settings_screen.dart`, replace the two-line privacy string in the About card:

```dart
                  'All data is stored privately on this device. '
                  'No account, no cloud, fully offline.',
```

with:

```dart
                  'All your tracking data is stored privately on this device. '
                  'No account, no cloud sync. The app contacts GitHub only to '
                  'check for and download updates.',
```

- [ ] **Step 4: Correct the README**

Replace the Android Manifest Notes paragraph (currently: "The app declares `POST_NOTIFICATIONS` and `RECEIVE_BOOT_COMPLETED` permissions for the optional daily reminder. No network permission is declared — the app is fully offline.") with:

```markdown
The app declares `POST_NOTIFICATIONS` and `RECEIVE_BOOT_COMPLETED` for the
optional daily reminder, and `INTERNET` plus `REQUEST_INSTALL_PACKAGES` for the
in-app updater. The media-read permissions that `open_filex` declares are
stripped in the manifest — the updater only ever opens an APK from the app's own
cache directory.

Your tracking data never leaves the device. The only outbound requests are to
`api.github.com` for release metadata and to GitHub's asset host for the APK.
```

Add a feature section describing the updater, placed after the Theme section:

```markdown
### Updates
The app installs as a sideloaded APK, so it checks GitHub Releases for a newer
version itself. **Settings ▸ Updates** checks on demand; the app also checks
quietly at most once every 24 hours on launch and puts a dot on the Settings tab
when something newer exists. Downloads show progress, then hand the APK to
Android's installer, which asks you to confirm.

"Later" keeps a version quiet until a newer one appears. A failed background
check is silent — only a check you asked for reports errors. Android-only:
the section is hidden on iOS.

> Release APKs must keep a stable signing key. Android refuses to install an
> update signed with a different key than the installed app, with a confusing
> system error.
```

Update the Architecture tree to include the new files:

```
├── core/models/        # ModeDefinition, TrackedLevel, ContentPack, DayEntry,
│                       # Achievement, AppRelease
├── services/           # StatsService, AchievementService, NotificationService,
│                       # ExportImportService, UpdateService
├── viewmodels/         # TrackerViewModel, ModeViewModel, SettingsViewModel,
│                       # UpdateViewModel
```

And the Dependencies table gains a row:

```markdown
| `open_filex` | Hands a downloaded APK to Android's package installer |
```

- [ ] **Step 5: Verify**

Run: `export PATH="$HOME/flutter/bin:$PATH" && flutter analyze`
Expected: `No issues found!`

Run: `flutter test`
Expected: 108 tests pass.

Confirm no stale offline claim survives:

```bash
grep -rn "fully offline" lib README.md
```
Expected: no output.

- [ ] **Step 6: Commit**

```bash
git add lib/main.dart lib/ui/shell/home_shell.dart lib/ui/settings/settings_screen.dart README.md
git commit -m "feat: wire up the updater and correct the offline claims"
```

---

## Notes for the implementer

**`flutter build apk` will not work here.** Only Java 25 is installed; Gradle 8.14 needs 17 or 21. This is environmental. Report the error, never treat it as a code defect, and never edit `android/gradle.properties` to work around it — a failed build sometimes auto-edits that file, so check `git status` afterwards and revert it if it changed.

**`pub get` can rewrite `android/local.properties`.** Only Task 3 needs to run it. Afterwards confirm `sdk.dir=/home/ben/Android/Sdk`.

**Nothing in this feature can be exercised end to end here** — no emulator, no `adb`, no device, and the project targets only `android/` and `ios/`. The network calls, the download, the installer hand-off, the manifest merge and every pixel of the UI are unverified by construction. Say so plainly rather than implying otherwise; the branch owner will verify on a device.

**The existing suite is 74 tests and must stay green.** This plan adds 34, ending at 108.

**Test database isolation does not apply here.** None of this feature's tests touch `AppDatabase`; they use `SharedPreferences.setMockInitialValues({})` only. Do not add temp-database plumbing they do not need.
