# In-App Updater — Design

**Date:** 2026-09-11
**Status:** Requirements captured; to be planned after the tracking-modes plan lands.

## Summary

The app installs as a sideloaded APK from GitHub Releases, so there is no store
to deliver updates. This adds an in-app updater: the app checks the repository's
latest release, tells the user when a newer version exists, downloads the APK
with visible progress, and hands it to Android's package installer.

## Decisions

| Question | Decision |
|---|---|
| Scope | Full in-app updater — check, download, and launch the installer. |
| Check timing | Manual "Check for updates" in Settings, plus a silent check at most once per 24h on launch. Never blocks startup. |
| Permissions | `INTERNET` and `REQUEST_INSTALL_PACKAGES` are both added. |
| Auth | None. `13/dontdrink` is public, so the releases API needs no token. |

### The offline promise has to change

This is the part that is not just additive. The app currently declares **no**
network permission, and says so in two user-visible places:

- `README.md`: "No network permission is declared — the app is fully offline."
- The About card in Settings: *"All data is stored privately on this device.
  No account, no cloud, fully offline."*

Both become false the moment `INTERNET` is declared. The **data** claim stays
true — no tracking data ever leaves the device, and the only outbound requests
are to `api.github.com` and `objects.githubusercontent.com` for release metadata
and the APK. The copy must be rewritten to say exactly that rather than
"fully offline", e.g.:

> All your tracking data is stored privately on this device. No account, no
> cloud sync. The app contacts GitHub only to check for and download updates.

`REQUEST_INSTALL_PACKAGES` is a sensitive permission. It is correct for a
sideloaded app, but it would attract policy review if this app were ever
submitted to Google Play. Noted so the choice is deliberate.

## Release format this relies on

From `.github/workflows/release.yml`, which is already in place:

- Trigger: a pushed tag matching `v[0-9]*` (e.g. `v1.2.3`).
- Release name: `Don't Drink v1.2.3`; `generate_release_notes: true`.
- Exactly one asset, named `dont-drink-v1.2.3.apk`.
- `--build-name` is the tag minus `v`; `--build-number` is the CI run number.

Current installed version comes from `package_info_plus` (already a dependency):
`version` (e.g. `1.1.1`) and `buildNumber`.

**Version comparison is on the semver `version` string, not the build number.**
Build numbers come from `github.run_number`, which increments per workflow run
and is therefore not comparable across re-runs. Parse `tag_name`, strip the
leading `v`, and compare numerically component-by-component (major, minor,
patch) — never with string comparison, which makes `1.10.0` sort below `1.9.0`.

## Components

```
lib/
├── core/models/
│   └── app_release.dart        AppRelease { version, tagName, notes,
│                                            apkUrl, apkSizeBytes, publishedAt }
├── services/
│   └── update_service.dart     fetchLatest(), compareVersions(), downloadApk(),
│                               installApk()
├── viewmodels/
│   └── update_viewmodel.dart   UpdateState machine + last-check throttle
└── ui/settings/widgets/
    └── update_section.dart     the Settings ▸ Updates card
```

`SettingsRepository` gains two keys: `last_update_check` (epoch ms, drives the
24h throttle) and `skipped_version` (so "Later" on a given version stays quiet
until a newer one appears).

### State machine

`UpdateState` is a sealed class, mirroring the existing `ImportResult` pattern
in `export_import_service.dart`:

```
UpdateIdle
UpdateChecking
UpdateUpToDate(currentVersion)
UpdateAvailable(AppRelease)
UpdateDownloading(AppRelease, receivedBytes, totalBytes)
UpdateReadyToInstall(AppRelease, File)
UpdateError(message)
```

The UI renders one row per state. Download progress is a determinate bar driven
by `receivedBytes / totalBytes`.

### Networking

Use `dart:io`'s `HttpClient` rather than adding a package: it streams the
response, which is what a progress bar needs, and it keeps the dependency count
flat. Two calls:

1. `GET https://api.github.com/repos/13/dontdrink/releases/latest`
   with `Accept: application/vnd.github+json` and a `User-Agent` header (GitHub
   rejects requests without one). Parse `tag_name`, `body`, and the single
   entry in `assets[]` whose `name` ends in `.apk` — read `browser_download_url`
   and `size`.
2. `GET <browser_download_url>`, streamed to
   `getTemporaryDirectory()/dont-drink-<tag>.apk`.

Failure handling: unreachable network, non-200, malformed JSON, and a release
with no APK asset all resolve to `UpdateError` with a readable message. A failed
*silent* check is swallowed entirely — it must never surface a dialog or
snackbar on launch.

### Installing

Launching Android's package installer needs a `FileProvider`, because a
`file://` URI targeting another app throws `FileUriExposedException` on
Android 7+. Required:

- `android/app/src/main/AndroidManifest.xml`: the two permissions, plus a
  `<provider>` for `androidx.core.content.FileProvider` with
  `android:grantUriPermissions="true"` and an exported
  `android.support.FILE_PROVIDER_PATHS` meta-data.
- `android/app/src/main/res/xml/file_paths.xml`: a `<cache-path>` entry
  covering the download directory.
- On Android 8+, `REQUEST_INSTALL_PACKAGES` is granted per-app at runtime;
  if the user has not granted it, the install intent opens the
  "Allow from this source" settings screen instead of failing silently.

Package choice: `open_filex` to hand the APK to the system installer — it is
maintained, small, and does the FileProvider plumbing. This is the one new
runtime dependency.

## iOS

The updater is Android-only. On iOS the Settings section is hidden entirely —
sideloading an IPA this way is not possible, and showing a dead control would be
worse than showing nothing. Guard on `Platform.isAndroid`.

## Testing

- **Version comparison** is the piece most likely to be silently wrong, and it
  is pure — test it directly: `1.10.0 > 1.9.0`, `1.2.0 > 1.2`, equal versions,
  a malformed tag, and a tag with and without the `v` prefix.
- **Release parsing** from a captured GitHub JSON fixture, including a release
  whose assets list contains no APK.
- **The 24h throttle**: a silent check within the window makes no request; one
  outside it does.
- **Skipped version**: after skipping `1.2.0`, a silent check finding `1.2.0`
  stays quiet, but one finding `1.3.0` surfaces.
- Download and install are platform-bound and covered by manual verification,
  not unit tests.

## Risks

- **`REQUEST_INSTALL_PACKAGES` is sensitive.** Correct for sideloading, but it
  forecloses an easy Play Store submission later.
- **The updater can brick its own upgrade path.** A release whose APK is signed
  with a different key than the installed app fails to install with a confusing
  system error. The signing key must stay stable across releases; worth a line
  in the README.
- **Unauthenticated GitHub API is rate-limited** to 60 requests/hour per IP.
  The 24h throttle keeps normal use far beneath that, but a user hammering the
  manual button can hit it; surface the API's own message rather than a generic
  failure.
