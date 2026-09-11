# Tracking Modes — Design

**Date:** 2026-09-11
**Status:** Approved for planning

## Summary

Today the app tracks one habit: alcohol. This adds **tracking modes** — Don't
Drink, Don't Smoke, No Contact, and user-created Custom modes. Each active mode
keeps its own independent history, streak, calendar, achievements and content.
A switcher in the Dashboard app bar changes which mode the app is showing;
Settings owns activation and custom-mode creation.

The app's name, launcher icon and About card stay "Don't Drink". Modes re-label
content, not the product.

## Decisions

| Question | Decision |
|---|---|
| Multiple active modes | Separate, switchable. Each mode has its own history; one is in view at a time. |
| Logging scale | Per-mode. Each mode ships its own levels; Custom uses a fixed Clean/Slip/Relapse scale. No level editor. |
| Content | Full pack per built-in mode (achievements, facts, recovery, motivations). Custom falls back to generic. |
| Switcher | Dashboard app-bar title dropdown for switching; Settings ▸ Modes for activation. |
| Representation | Mode as data: a `ModeDefinition` registry, built-ins `const`, custom modes as DB rows. |

### Rejected alternatives

- **One database file per mode.** Strong isolation, but export/import, any
  future cross-mode overview, and N custom-mode files all get ugly — and it
  still needs the registry for levels and content. `WHERE mode_id = ?` buys the
  same isolation.
- **Mode as a plain enum with `switch`-based content.** Smallest diff, but
  custom modes cannot exist as data.

## Data model

```
core/models/
  mode_definition.dart   ModeDefinition { id, name, emoji, levels, isBuiltIn }
  tracked_level.dart     TrackedLevel  { value, label, shortLabel, meaning,
                                         color, emoji, isClean }
  content_pack.dart      ContentPack   { achievements, facts,
                                         recoveryMilestones, motivations }
  day_entry.dart         + modeId
```

`TrackedLevel` replaces the `DrinkLevel` enum as a plain value object owned by
its mode. Its `value` remains the persisted integer, so Don't Drink's existing
0–4 rows keep their exact meaning.

- `DrinkLevel.isAlcoholFree` → `TrackedLevel.isClean`. The streak rule
  generalizes to "this level counts as a clean day".
- `DrinkLevel.onColor` (a per-case switch) → a computed luminance check, since
  the set of colors is no longer fixed.
- `app_colors.dart`'s `DrinkLevel` → color mapping is dropped; each mode's
  levels carry their own colors.

### Level scales

Value `0` is the clean day in every mode, keeping the streak rule uniform.

| | 0 | 1 | 2 | 3 | 4 |
|---|---|---|---|---|---|
| Don't Drink | None | 1–2 | 3–5 | 6+ | Blackout |
| Don't Smoke | None | 1–5 | 6–15 | 16+ | Binge |
| No Contact | No contact | Thought about it | Checked profile | Reached out | — |
| Custom | Clean | Slip | Relapse | — | — |

No Contact and Custom have **fewer than five levels**. Every UI that currently
iterates `DrinkLevel.values` must iterate `mode.levels` instead.

### Database — schema version 2

```sql
ALTER TABLE day_entries ADD COLUMN mode_id TEXT NOT NULL DEFAULT 'dont_drink';
-- SQLite cannot add a primary key via ALTER, so rebuild:
--   create day_entries_v2 with PRIMARY KEY (mode_id, date_key),
--   copy rows, drop old, rename — all inside one transaction.

CREATE TABLE modes (          -- custom modes only; built-ins are const
  id         TEXT PRIMARY KEY,
  name       TEXT NOT NULL,
  emoji      TEXT,
  created_at INTEGER NOT NULL
);
```

Every existing row becomes a Don't Drink row. No data loss, no user action.

## Mode registry and content packs

```
data/static/modes/
  mode_registry.dart        kBuiltInModes + lookup by id
  dont_drink_mode.dart      levels + ContentPack
  dont_smoke_mode.dart      levels + ContentPack
  no_contact_mode.dart      levels + ContentPack
  custom_mode.dart          level template + generic ContentPack
```

Each mode file is one `const ModeDefinition` holding its levels and its
`ContentPack`.

The existing content **types** stay shared and stay where they are — `Fact`,
`Achievement`, `RecoveryMilestone`, `RecoveryTier`. Only the `const` lists move:
`kAlcoholHarms`, `kBenefits`, `kAchievements` and `kMotivations` become fields
of Don't Drink's pack, and other modes supply lists of the same types.

`RecoveryTier` labels ("The Acute Phase", "The Regeneration Phase") are generic
enough for all modes, so tiers remain shared; each mode supplies its own
milestones within them. No Contact's milestones are psychological rather than
physiological ("Day 3 — the urge peaks and starts to fall") but fit the same
shape.

`ContentPack` fields default to `const []`. **Custom mode ships generic streak
achievements and habit-neutral motivations, and supplies no facts or recovery
milestones** — the More screen hides those two rows when the active mode's
lists are empty. This is the one place the "full pack per mode" decision must
degrade: nobody can write content ahead of time for a mode the user names.

## Services and view models

```
data/repositories/
  mode_repository.dart      custom-mode CRUD + which modes are active
  entry_repository.dart     every method gains a mode parameter
viewmodels/
  mode_viewmodel.dart       NEW — active mode, enabled modes, custom CRUD
  tracker_viewmodel.dart    scoped to one mode; reloads on switch
```

**`ModeRepository`** owns the `modes` table and two `SharedPreferences` keys:
`enabled_mode_ids` (list) and `active_mode_id` (single). Built-ins are `const`
and are never written to the table.

**`ModeViewModel`** exposes `activeMode`, `enabledModes`, `allAvailableModes`,
`setActive(id)`, `setEnabled(id, bool)`, `createCustom(name, emoji)`,
`deleteCustom(id)`. **Multiple custom modes are allowed** — each is its own row
with its own id, and all share the Clean/Slip/Relapse template.

**Per-mode streak summaries.** Both the switcher and the Settings list show a
current streak for modes that are *not* active, but `TrackerViewModel` only
holds the active mode's entries. `ModeViewModel` therefore also exposes
`streakFor(modeId)`, backed by a `Map<String, int>` it builds by asking
`EntryRepository` for each enabled mode's entries and running `StatsService`
over them. It refreshes on load, on activation changes, and after
`TrackerViewModel` logs a day. The dataset is at most one row per day per mode,
so recomputing all of them is cheap.

**Switch wiring.** `TrackerViewModel.switchMode(ModeDefinition)` swaps its
`_mode`, reloads that mode's entries and recomputes. `ModeViewModel` takes a
`Future<void> Function(ModeDefinition) onActiveModeChanged` callback, wired in
`main()` to `trackerVm.switchMode`. This is explicit and testable, and avoids a
`ChangeNotifierProxyProvider` rebuild storm — `TrackerViewModel` stays
constructed and `await`ed before `runApp`.

**Startup ordering changes** in `main()`. `TrackerViewModel` can no longer load
in parallel with the rest, because it needs to know which mode it is scoped to:

1. `ModeRepository` resolves the active mode (falling back to `dont_drink` when
   the stored id names a custom mode that no longer exists).
2. `TrackerViewModel` is constructed with that mode and loaded.
3. `SettingsViewModel.load()` still runs in parallel with step 2.

**`StatsService`** needs no mode parameter — `TrackedLevel` carries `isClean`,
so streak logic reads `entry.level.isClean`. Alcohol-specific field names are
renamed: `totalAlcoholFreeDays` → `totalCleanDays`, `alcoholFreePercentage` →
`cleanDayPercentage`. `levelCounts` is keyed by `TrackedLevel` and is therefore
only meaningful within one mode.

**`EntryRepository`** must thread the mode through: `DayEntry.fromMap(map, mode)`
can no longer resolve an `int` to a level on its own, and every query gains
`WHERE mode_id = ?`.

**`AchievementService`** takes `List<Achievement>` as a parameter instead of
importing `kAchievements`. Unlock state stays derived from the mode's own
longest streak, so nothing new is persisted and badges cannot leak between
modes. Achievement ids are nonetheless **mode-prefixed** (`dont_drink.day_30`,
`dont_smoke.day_30`): the existing ids (`day_1`, `day_30`) would collide across
packs the moment anything persists them, and `Achievement.id` is already
documented as being for exactly that.

**Notifications stay global.** One reminder at one time — three active modes
must not mean three nightly pings. The body ("How did today go? Tap to log your
day.") is already mode-neutral; only the title changes.

**Export/import becomes multi-mode.** Payload moves to `version: 2`, carrying
all modes' entries plus any custom mode definitions. A `version: 1` file still
imports, with its entries assigned to `dont_drink` — which is what they already
were. Importing a backup containing a custom mode recreates that definition.

## UI

### New

- `ui/settings/widgets/modes_section.dart` — the Settings ▸ Modes list:
  enabled checkbox, mode emoji, name, current streak, active marker, edit and
  delete for custom modes, and a "Create custom mode" row.
- `ui/modes/custom_mode_editor.dart` — name + emoji entry for a custom mode.
- `ui/widgets/mode_switcher.dart` — a `PopupMenuButton` replacing the Dashboard
  app-bar title, showing each enabled mode with emoji and current streak, a
  checkmark on the active one, and a "Manage modes…" row that deep-links into
  Settings.

### Activation rules

- A mode cannot be deactivated while it is the active one.
- The last enabled mode cannot be turned off — the switcher must always have
  somewhere to land.
- Deactivating **keeps** the data. The confirm dialog says so explicitly;
  "off" reading as "erased" is the obvious user fear here.
- Deleting a custom mode **does** drop its entries, and that dialog names the
  entry count.

### Changed — the five-level assumption

Four files iterate `DrinkLevel.values` and must iterate `mode.levels`:

- `ui/widgets/day_entry_sheet.dart` — the level picker.
- `ui/statistics/widgets/distribution_pie.dart` — pie sections.
- `ui/calendar/calendar_screen.dart` and `ui/calendar/widgets/month_grid.dart` —
  legend and day-cell coloring.
- `ui/dashboard/widgets/month_summary_card.dart` — per-level counts row.

### Changed — hardcoded copy

`more_screen.dart` ("Harms of alcohol & benefits of quitting"),
`facts_screen.dart`, `recovery_screen.dart`, `dashboard/widgets/streak_hero.dart`,
`dashboard/widgets/quick_stats_row.dart` and `achievements_screen.dart` read
from the active mode's name and pack rather than literals. `home_shell.dart`'s
tab labels are already neutral.

## Testing

`test/stats_service_test.dart` (7 tests) is ported to a `TrackedLevel` fixture
and keeps its coverage. New tests:

1. **Migration v1 → v2** — an in-memory v1 database with entries, opened at v2,
   has every row assigned `dont_drink` and the composite primary key in place.
   Written first; it is what protects real user data.
2. **Mode isolation** — entries logged in two modes on the same date do not
   collide; each mode's streak and achievements see only their own rows.
3. **Activation rules** — cannot deactivate the active mode; cannot disable the
   last enabled mode.
4. **Import compatibility** — a `version: 1` payload lands in Don't Drink; a
   `version: 2` payload restores multiple modes plus custom definitions.

## Risks

- **The composite-PK migration** is the highest-risk change: it rebuilds the
  user's only data table. Mitigated by writing its test first and running the
  rebuild inside a single transaction.
- **Custom mode has no hand-written facts or recovery timeline**, so those two
  screens hide themselves for it. Accepted.
