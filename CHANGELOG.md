# Changelog

What changed in each release, written for the person using the app rather than
the person who wrote it. Newest first.

The GitHub release notes are generated from commit subjects; this file is the
curated version, and it is what an in-app "what's new" should read from.

## 1.5.3 — 2026-09-13

### Fixed
- Export can now put a backup on the device. It used to open the share sheet,
  which on many phones offers no file manager at all, so the backup had
  nowhere to go. Export opens the system save dialog; sharing a backup to
  another app is its own row.
- Badge titles and descriptions stayed English under a German or Italian
  interface. Everything else on the screen was translated, which made the app
  disagree with itself.
- Dates read as English sentences with translated words — "Sonntag, September
  13, 2026" instead of "Sonntag, 13. September 2026". Each language now writes
  dates its own way.

## 1.5.2 — 2026-09-13

### Fixed
- In the month picker, the month you are currently viewing showed as a filled
  button with its label clipped away to a few pixels — worse the larger your
  text size. Every month now uses the same button, and the row height follows
  your text setting.

## 1.5.1 — 2026-09-13

### Fixed
- The month picker would only let you open months you had already logged in,
  so on a fresh install eleven of the twelve buttons were greyed out and
  back-filling last week — the reason to open it — was the one thing it
  refused. Every past month is selectable now; ones without entries are simply
  dimmed.

### Changed
- Removed the expand arrow beside the dashboard's month name. The month name
  itself opens the picker, and the calendar lives under More.

## 1.5.0 — 2026-09-13

### Added
- Notes. Any logged day can carry one — what happened, how it felt — folded
  behind "Add a note" so logging stays a single tap. Days with a note are
  marked in the calendar, and a **Notes** screen lists everything you have
  written, newest first. Notes are in your backups and never in a shared image.
- A **yearly view** under More: every day of a year as one cell, so a year
  reads as a pattern rather than a list.
- Sharing. A month, a year or an earned badge can be sent as an image. The
  picture carries the grid and the period only — no counts, no rates, never a
  note — and a badge card shows exactly what will be shared before it leaves
  the device.
- Tapping the month name jumps straight to another month, with months that hold
  entries picked out.
- Tapping a slice of the distribution donut shows that level's day count.
- A short welcome card on a fresh install, which retires itself as soon as you
  log anything.

### Changed
- A tracked day rolls over at 4 AM instead of midnight, so logging a night out
  at 1 AM records the night that just happened rather than the day that started
  an hour ago.
- The statistics screen follows the month you are looking at. It always showed
  the current month, so stepping back to August and opening Stats still showed
  September.
- Shared images render in a fixed light palette, so a picture taken in dark
  mode is readable wherever it is sent.
- The calendar, the yearly heatmap, the donut and the badges are now described
  for screen readers; before this they communicated entirely through colour.

### Fixed
- The log sheet could clip its bottom option on a short screen or at a large
  text size.
- Logging a day no longer re-reads the whole history of every enabled mode.

## 1.4.0 — 2026-09-13

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
