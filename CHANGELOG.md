# Changelog

What changed in each release, written for the person using the app rather than
the person who wrote it. Newest first.

The GitHub release notes are generated from commit subjects; this file is the
curated version, and it is what an in-app "what's new" should read from.

## Unreleased

### Added
- Every logged day now gets a response, not only the ones that earn a badge. A
  clean day gets a short acknowledgement headed by the streak count; a day that
  went badly gets the same calm note whatever the level, because ranking how bad
  a day was is not this app's job. The message says that earned badges and your
  best streak stay yours, and offers a way into Motivation without insisting.
- The Facts screen, the recovery timeline, the full calendar and the Motivation
  screen are reachable again, from a More tab. They shipped in every previous
  release with no route to them at all.

### Changed
- Android's cloud backup is switched off. It was on by default, which meant the
  tracking database could be uploaded to your Google account while the About
  card promised the data stays on this device. Direct device-to-device transfer
  to a new phone still works.
- The About card shows the date the APK was actually built instead of a
  hardcoded one that had been wrong for months.
- Updater errors are translated instead of always appearing in English.

### Fixed
- The log sheet could clip its bottom option on a short screen or at a large
  text size; it scrolls now.
- Custom mode ids are random rather than the creation timestamp, so two devices
  cannot file different habits under the same id.

## 1.3.0 — 2026-09-11

### Added
- German and Italian, throughout: the interface, the achievement names, the
  facts, the recovery timeline, the motivations and the level scale. The app
  follows the system language and a Settings picker overrides it.
- Achievements are repeatable and counted. Reaching a week five separate times
  is now five earnings, shown as a ×5 on the badge with the first and last
  dates, instead of a single unlock from months ago.

### Changed
- The dashboard's next-achievement progress follows your current streak: after
  a relapse, the next goal is the first milestone again.
- The celebration says which time it was, and keeps its confetti for the
  legendary milestones on every earn.

### Fixed
- The new-mode sheet hid its name field behind the keyboard.
- Back-filling a forgotten day now correctly earns any badge that day completes.

## 1.2.0 — 2026-09-11

### Fixed
- Released APKs are signed with a stable release key. Every earlier release was
  signed by a throwaway key generated per CI run, so no two carried the same
  certificate and the in-app updater could never install over a running build.
  **Coming from 1.1.1 or earlier, uninstall once before installing this.**

## 1.1.1 — 2026-06-09

### Fixed
- Notification setup failures no longer take down startup.
- Import reports skipped entries with correct pluralisation.

## 1.1.0 — 2026-06-05

### Added
- Tracking modes: Don't Drink, Don't Smoke, No Contact, plus custom modes with
  their own clean days, slips and relapses. Each mode keeps its own history,
  streaks and badges.
- Export and import cover every mode, and can still read a 1.0.0 backup.

## 1.0.0

First release: daily logging, streaks, a calendar, statistics, achievements,
the recovery timeline, facts and motivations — all stored on the device.
