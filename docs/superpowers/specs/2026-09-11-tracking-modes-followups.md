# Tracking Modes — Known Follow-ups

Everything below was found during implementation review and deliberately **not**
fixed, either because it was out of scope, judged acceptable, or too risky to
change unverified at the end of the run. Nothing here blocks merge. Recorded so
the decisions do not have to be rediscovered.

Spec: `2026-09-11-tracking-modes-design.md` · Plan: `../plans/2026-09-11-tracking-modes.md`

## Needs a decision from the maintainer

**The nightly reminder always says "Don't Drink".** This is the one spec line
that was not built — the spec's notifications paragraph says "only the title
changes", i.e. the title should be mode-aware. Global scheduling (one reminder,
never one per active mode) is correct and settled; the title is not. A No Contact
user gets a nightly "Don't Drink" ping. Deferred because it needs a reschedule
hook on every mode switch, and notification scheduling could not be exercised in
the build environment at all — shipping an unverified change to the one subsystem
that fires while the app is closed was the worse risk.

**Five screens are unreachable dead code.** `more_screen.dart` and
`calendar_screen.dart` are imported by nothing in `lib/`; `facts_screen.dart`,
`motivation_screen.dart` and `recovery_screen.dart` are reachable only through
`more_screen`. `HomeShell` has four tabs — Dashboard, Awards, Stats, Settings —
so commit `2c8fcee` ("removed timeline") appears to have dropped the More tab
without deleting the screens behind it. They were kept mode-aware anyway, so
restoring the tab is a one-line change; deleting them is also fine. Carrying them
has a real cost: the final review found that the spec's stated mitigation for
custom modes (hiding the Facts and Recovery rows) had been implemented entirely
against `more_screen` — dead code — while the one *live* recovery surface, the
Awards Recovery tab, went unguarded. That bug is fixed, but the dead code is why
nobody noticed it for four tasks.

**A restored backup leaves non-default modes present but disabled.** The payload
carries no `enabled_mode_ids` / `active_mode_id`, so restoring onto a fresh
install shows only Don't Drink. The data is all there and one tap away in
Settings ▸ Modes, but a user may reasonably conclude their other modes were lost.
Either carry the enabled set in the backup, or name the restored-but-disabled
modes in the post-import snackbar.

**Existing users see no sign the feature exists.** With one mode enabled,
`ModeSwitcher` renders plain text with no dropdown affordance — correct, but it
means the dashboard looks unchanged after upgrade until the user opens
Settings ▸ Modes. Worth a release note or a one-time hint.

## Accepted trade-offs

- **A genuine database error during import is now counted as a skipped row**
  rather than surfacing as `ImportError`. A wholly failed import reports
  `ImportSuccess(0, skipped: N)`. This is the direct consequence of making a
  malformed row skip instead of aborting the file, and is the better default —
  noted so the trade-off is on record.
- **`updated_at` does not survive an import.** `EntryRepository.upsert` stamps
  `DateTime.now()`, so the exported timestamp is written to the backup and
  discarded on the way back in. Nothing reads `updatedAt`; this is fidelity, not
  behaviour. Pre-existing — the same was true before tracking modes.
- **`restoreCustom` stamps `created_at` to now**, so restored custom modes
  re-order relative to their original creation sequence (`customModes()` orders
  by `created_at ASC`).
- **`deleteCustom` is not transactional** across its mode-row, entries and
  preferences writes. An interruption can orphan rows — but they are rows the
  user just confirmed deleting, and `resolveActiveMode` tolerates the
  intermediate state.
- **Custom modes have no facts and no recovery timeline** by design; those
  sections hide themselves. The README conveys this by contrast in the mode
  table rather than stating it outright.

## Small cleanups

- `TrackedLevel`'s `==`/`hashCode` compare only `value` and `label`. Safe while
  levels are `const` singletons per mode; revisit if anything ever constructs
  them dynamically.
- `EntryRepository.getRange` / `getMonth` / `levelCounts` have no production
  caller and no isolation test. Their `mode_id` predicates are correct but
  unprotected. Delete or cover.
- `EntryRepository.upsert` does not validate `entry.modeId`. No current write
  path can supply an unknown id, so this is defensive only.
- `ModeViewModel.enabledModes` filters unresolvable ids via `.nonNulls`, while
  `setEnabled`'s last-mode guard counts raw `_enabledIds`. No path produces a
  ghost id today; counting `enabledModes.length` would close it for free.
- `modes_section._toggle` catches only `ModeRuleError`, so a persistence failure
  inside `setEnabled` escapes unhandled.
- `_busy` gates only the delete button; the tile's `onTap`, the edit button and
  the Switch stay live during an in-flight delete.
- `test/tracker_viewmodel_test.dart`'s `visibleMonth` assertion is vacuous — the
  field is already initialised to the current month and the test never navigates
  away, so it would pass even if the reset were removed. A `previousMonth()`
  before the switch would make it real.
- `_RecoveryEmptyState`'s copy says "Custom modes don't have a recovery timeline"
  while rendering under the more general `!hasRecovery`. Equivalent today.
- Five formerly-named colours are now duplicated as magic literals across five
  files. They are app-chrome accents unrelated to tracking status and arguably
  belong back in `AppColors` under non-status names.
- The README's Streak Counter, Statistics and Recovery sections still use
  Don't-Drink vocabulary for features that are now mode-parameterised.

## Environment notes (not code issues)

- **`flutter build apk` fails on the dev machine used for this work** — only
  Java 25 is installed, and `.github/workflows/release.yml` pins Java 21
  precisely because "Java 25 blocks System::load used by Gradle's native libs".
  CI is unaffected; local APK builds need a JDK 17 or 21.
- **Nothing in this branch was run on a device.** The project targets only
  `android/` and `ios/`, and no emulator or `adb` was available. 74 automated
  tests pass and every change was code-reviewed, but the Settings mode list, the
  custom mode editor and the dashboard switcher have never been executed.
</content>
