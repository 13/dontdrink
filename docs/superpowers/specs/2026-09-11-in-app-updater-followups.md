# In-App Updater — Known Follow-ups

Everything below was found during implementation review and deliberately **not**
fixed on that branch, either because it needs something only the repository
owner can supply, or because it was judged an acceptable trade-off. Recorded so
the reasoning does not have to be rediscovered.

Spec: `2026-09-11-in-app-updater-design.md` · Plan: `../plans/2026-09-11-in-app-updater.md`

---

## BLOCKER — release APKs are signed with the debug keystore

**The updater cannot install anything until this is fixed.** This is not a
defect in the updater code; it is a pre-existing gap the feature now depends on.

`android/app/build.gradle.kts` still carries the Flutter template's default:

```kotlin
release {
    // TODO: Add your own signing config for the release build.
    // Signing with the debug keys for now, so `flutter run --release` works.
    signingConfig = signingConfigs.getByName("debug")
}
```

and `.github/workflows/release.yml` has no keystore step, no `key.properties`,
and no secrets. GitHub-hosted runners are ephemeral and carry no
`~/.android/debug.keystore`, so the Android Gradle Plugin generates a fresh one
with a **random key pair on every run**. Every published release is therefore
signed with a different certificate.

Android refuses to install an update whose signing certificate differs from the
installed app's. Every in-app update will fail with
`INSTALL_FAILED_UPDATE_INCOMPATIBLE`, surfaced to the user as the opaque
"App not installed" system dialog — from which the app has no diagnosable path
back, because it cannot distinguish "the user declined" from "Android refused".

The spec listed stable signing as a risk and the branch's response was a README
warning asserting the precondition. The precondition does not hold.

**To fix, once:**

1. Generate a release keystore and store it somewhere durable. Losing it means
   never being able to update existing installs again — not from CI, not by
   hand.
2. Add the keystore (base64-encoded) and its passwords as repository secrets.
3. In `release.yml`, decode the keystore and write a `key.properties` before the
   build step.
4. In `build.gradle.kts`, replace the debug `signingConfig` with a real
   `signingConfigs.create("release")` reading from `key.properties`.
5. Verify: run two consecutive CI releases and confirm
   `apksigner verify --print-certs` reports the same certificate fingerprint for
   both.

**Do not tag a release advertising the updater until step 5 passes.**

---

## Verify once, on a real device

Nothing in this feature has been executed — no build, no emulator, no device.
These are the checks that need a human and a phone:

- **The install hand-off.** `installApk` → `OpenFilex.open` → `FileProvider` →
  `ACTION_VIEW` is a platform-channel round trip through a third-party plugin's
  Java. It was traced statically and should work (the cache path sits inside
  `applicationInfo.dataDir`, so no media permission is consulted), but static
  tracing is not running it.
- **The merged manifest.** Whether the four `tools:node="remove"` stanzas
  actually stripped `open_filex`'s media permissions is only provable from a
  built APK:
  ```
  aapt2 dump permissions build/app/outputs/flutter-apk/app-release.apk
  ```
  Expect exactly: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `INTERNET`,
  `REQUEST_INSTALL_PACKAGES`, and `VIBRATE` (the last from
  `flutter_local_notifications`, pre-existing). No `READ_MEDIA_*`, no
  `READ_EXTERNAL_STORAGE`.
- **The typeface.** Inter is now bundled and `google_fonts` runtime fetching is
  disabled. If an asset filename were ever wrong the app silently renders in the
  platform default instead — there is a test that catches it, but see the note
  about stale `build/unit_test_assets/` below.
- **Every state of the Settings ▸ Updates card**, which has no widget tests:
  idle, checking, up-to-date, available, downloading, ready, and each of the
  three error rows.

---

## Accepted trade-offs

- **The cache sweep can theoretically race an install.** Downloaded APKs are
  swept on the *next* launch rather than deleted right after `installApk`,
  because the install intent is asynchronous and Android may still be reading
  the file. If the app process restarts while the installer is mid-read, the
  sweep can delete the file underneath it and the install aborts. Deleting
  immediately races the same hand-off harder. A mtime threshold — skip files
  younger than ~15 minutes — would remove the residual risk if it ever bites.
- **No cancel during a download.** Deliberate: there is no total-duration
  timeout either, because a large APK on a slow connection is legitimately slow.
  The connection timeout covers "never connects". On a stalled-but-not-dead
  connection the user's only escape is to leave Settings, and the download
  future keeps running.
- **A byte count disagreeing with GitHub's reported asset `size` is rejected**
  as truncated. Correct almost always, but a stale `size` in the API response
  would block updates entirely, with a message pointing at the network.
- **Unauthenticated rate limiting is per-IP** (60/hour). Handled with a specific
  message, but a user behind shared carrier NAT can hit it without doing
  anything unusual themselves.
- **`updateAvailable` keeps the Settings-tab badge lit for download and install
  errors**, dark for check errors — the first two carry a retained release and a
  one-tap Retry; a check error has nothing to act on. State is in-memory, so a
  persistently failing download clears the badge on the next launch.

---

## Small cleanups

- **The install-Retry path is untested.** Mutating `install()`'s
  `UpdateInstallError` guard to reject leaves the suite green; only the download
  retry is covered end to end. One test — call `install()` twice from a failing
  fake and assert the second attempt reached `installApk` — closes it.
- **`cleanUpDownloadedApks()` has no test**, because it calls
  `getTemporaryDirectory()` directly and would need injection to be unit-testable.
- **A stale `build/unit_test_assets/` can produce a false green** on the font
  asset test. Renaming a bundled font and re-running locally may still pass if
  that directory was not regenerated; on a clean checkout (and in CI) it fails
  correctly. Worth a `flutter clean` before trusting that test locally.
- **`Inter-ExtraBold.ttf` (422 KB) is bundled but never loaded.** `google_fonts`
  is only ever asked for Regular/Medium/SemiBold/Bold; the `FontWeight.w800`
  usages are `copyWith` on already-resolved theme styles and do not trigger a
  variant load. Dropping it saves a fifth of the 2.1 MB the fonts added.
- **`SettingsRepository.clearSkippedVersion()` is called only from its own test.**
  Harmless — a stale skipped version can never suppress a genuinely newer
  release — but it is an unused public method. Wire it into a successful install
  or drop it.
- **"Tap to download and install"** appears as a `ListTile` subtitle with no
  `onTap`; the real control is the Download button below it. Only reachable when
  GitHub reports no asset size.
- **`_StartupErrorApp`** uses a bare `TextStyle` with no family, so the rare
  startup-failure screen renders in the platform default rather than Inter.
- **The ~2.1 MB of bundled fonts** is not noted in the README, so a maintainer
  skimming only that file would not see the size cost.

---

## Environment notes (not code issues)

- **`flutter build apk` fails on the dev machine used for this work** — only
  Java 25 is installed, and `.github/workflows/release.yml` pins Java 21
  precisely because Java 25 breaks Gradle's native library loading. CI is
  unaffected; local builds need a JDK 17 or 21.
- **A note on why the fonts are bundled at all.** Adding `INTERNET` for the
  updater silently enabled `google_fonts` to fetch Inter from
  `fonts.gstatic.com` — a fetch that had been failing quietly for want of the
  permission. That would have made the About card's privacy claim false. Inter
  is now bundled under the SIL Open Font License and runtime fetching is
  disabled in `configureBundledFonts()`. If that call is ever removed, the app
  starts contacting Google again and the privacy copy becomes a lie; there is a
  test guarding it.
