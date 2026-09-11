# Tracking Modes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the user activate several tracking modes (Don't Drink, Don't Smoke, No Contact, and user-created Custom modes), each with its own independent history, streak, levels and content, and switch which one the app is showing.

**Architecture:** Modes are data. A `ModeDefinition` value object carries a mode's id, name, level scale and content pack; built-ins are `const` in `lib/data/static/modes/`, custom modes are rows in a new `modes` table. `day_entries` gains a `mode_id` column and a composite primary key `(mode_id, date_key)`. The `DrinkLevel` enum is replaced by `TrackedLevel`, a plain value object owned by its mode. `ModeViewModel` owns which mode is active; `TrackerViewModel` is scoped to exactly one mode and reloads when it changes.

**Tech Stack:** Flutter 3.41.2 / Dart 3.11.0 (via fvm), `provider` (MVVM), `sqflite` (SQLite), `shared_preferences`, `fl_chart`, `flutter_test`. New dev dependency: `sqflite_common_ffi` (so migration tests can run a real database on the host).

**Spec:** `docs/superpowers/specs/2026-09-11-tracking-modes-design.md`

## Global Constraints

- **Flutter is run through fvm.** Every `flutter` command in this plan is run as written; if `flutter` is not on PATH use `fvm flutter` instead. Do not change the pinned version.
- **`flutter analyze` must report "No issues found" at the end of every task.** The project uses `flutter_lints ^6.0.0`.
- **Persisted level integers must never change meaning.** Don't Drink's levels keep values 0–4 exactly as `DrinkLevel` had them: 0=None, 1=1–2, 2=3–5, 3=6+, 4=Blackout.
- **Value `0` is the clean day in every mode.** Every `ModeDefinition.levels` list has exactly one level with `isClean: true`, and it has `value: 0`.
- **Mode ids are stable strings.** Built-ins are exactly `dont_drink`, `dont_smoke`, `no_contact`. Custom mode ids are `custom_<millisecondsSinceEpoch>`.
- **Achievement ids are mode-prefixed**, e.g. `dont_drink.day_30`, `dont_smoke.day_30`. No two achievements anywhere share an id.
- **The app's own identity does not change.** App name, launcher icon, `MaterialApp.title` and the About card stay "Don't Drink". Modes re-label content only.
- **No new runtime dependencies.** Only the `sqflite_common_ffi` dev dependency is added.
- **The app stays fully offline.** No network permission, no account.

---

## File Structure

**Created:**

| File | Responsibility |
|---|---|
| `lib/core/models/tracked_level.dart` | `TrackedLevel` — one loggable status within a mode |
| `lib/core/models/content_pack.dart` | `ContentPack` — a mode's achievements, facts, recovery, motivations |
| `lib/core/models/mode_definition.dart` | `ModeDefinition` — id, name, emoji, levels, content |
| `lib/data/static/modes/dont_drink_mode.dart` | Don't Drink levels + pack (references existing alcohol content) |
| `lib/data/static/modes/dont_smoke_mode.dart` | Don't Smoke levels + pack (new content) |
| `lib/data/static/modes/no_contact_mode.dart` | No Contact levels + pack (new content) |
| `lib/data/static/modes/custom_mode.dart` | Custom level template + generic pack + `customModeFrom()` |
| `lib/data/static/modes/mode_registry.dart` | `kBuiltInModes`, `builtInModeById()` |
| `lib/data/repositories/mode_repository.dart` | Custom-mode CRUD, enabled/active ids, active-mode resolution |
| `lib/viewmodels/mode_viewmodel.dart` | Active mode, enabled modes, per-mode streaks, activation rules |
| `lib/ui/widgets/mode_switcher.dart` | Dashboard app-bar mode dropdown |
| `lib/ui/settings/widgets/modes_section.dart` | Settings ▸ Modes list |
| `lib/ui/modes/custom_mode_editor.dart` | Create/edit a custom mode (name + emoji) |
| `test/tracked_level_test.dart` | `TrackedLevel` behavior |
| `test/mode_registry_test.dart` | Built-in mode invariants |
| `test/migration_test.dart` | v1 → v2 schema migration |
| `test/mode_isolation_test.dart` | Per-mode entry isolation |
| `test/mode_viewmodel_test.dart` | Activation rules, switching, streaks |
| `test/export_import_test.dart` | v1 and v2 payload handling |

**Deleted:** `lib/core/models/drink_level.dart` (replaced by `TrackedLevel`).

**Modified:** `day_entry.dart`, `app_database.dart`, `entry_repository.dart`, `stats_service.dart`, `achievement_service.dart`, `export_import_service.dart`, `notification_service.dart`, `tracker_viewmodel.dart`, `app_colors.dart`, `main.dart`, `test/stats_service_test.dart`, plus the UI files listed in Tasks 6 and 8.

---

### Task 1: Core mode value types

**Files:**
- Create: `lib/core/models/tracked_level.dart`
- Create: `lib/core/models/content_pack.dart`
- Create: `lib/core/models/mode_definition.dart`
- Test: `test/tracked_level_test.dart`

**Interfaces:**
- Consumes: `Achievement` from `lib/core/models/achievement.dart`, `Fact` from `lib/data/static/facts_data.dart`, `RecoveryMilestone` and `RecoveryTier` from `lib/data/static/recovery_timeline_data.dart` (all already exist, unchanged).
- Produces:
  - `TrackedLevel({required int value, required String label, required String shortLabel, required String meaning, required Color color, required String emoji, bool isClean = false})` with `Color get onColor`.
  - `ContentPack({List<Achievement> achievements = const [], List<Fact> facts = const [], List<RecoveryMilestone> recoveryMilestones = const [], List<String> motivations = const [], String harmsTitle = 'Harms', String benefitsTitle = 'Benefits', String factsSubtitle = 'Harms & benefits', String recoverySubtitle = 'What you gain over time'})` with `hasFacts`, `hasRecovery`, `harms`, `benefits`, `recoveryByTier`.
  - `ModeDefinition({required String id, required String name, required String emoji, required String cleanDayLabel, required List<TrackedLevel> levels, required ContentPack content, bool isBuiltIn = true})` with `cleanLevel`, `levelForValue(int)`, `copyWith({String? name, String? emoji})`.

- [ ] **Step 1: Write the failing test**

Create `test/tracked_level_test.dart`:

```dart
import 'package:dont_drink/core/models/content_pack.dart';
import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/core/models/tracked_level.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _clean = TrackedLevel(
  value: 0,
  label: 'No Drinks',
  shortLabel: 'None',
  meaning: '0 alcoholic drinks',
  color: Color(0xFF4CAF50),
  emoji: '💚',
  isClean: true,
);

const _light = TrackedLevel(
  value: 1,
  label: '1–2 Drinks',
  shortLabel: 'Light',
  meaning: 'Light drinking',
  color: Color(0xFFFFC107),
  emoji: '🟡',
);

void main() {
  group('TrackedLevel.onColor', () {
    test('uses white on dark backgrounds', () {
      expect(_clean.onColor, Colors.white);
      expect(
        const TrackedLevel(
          value: 4,
          label: 'Blackout',
          shortLabel: 'Blackout',
          meaning: 'Extreme',
          color: Color(0xFF000000),
          emoji: '⚫',
        ).onColor,
        Colors.white,
      );
    });

    test('uses dark text on light backgrounds', () {
      expect(_light.onColor, Colors.black87);
      expect(
        const TrackedLevel(
          value: 2,
          label: '3–5 Drinks',
          shortLabel: 'Moderate',
          meaning: 'Moderate drinking',
          color: Color(0xFFFF9800),
          emoji: '🟠',
        ).onColor,
        Colors.black87,
      );
    });
  });

  group('TrackedLevel equality', () {
    test('levels from different modes with the same value are not equal', () {
      const otherModeClean = TrackedLevel(
        value: 0,
        label: 'No Cigarettes',
        shortLabel: 'None',
        meaning: '0 cigarettes',
        color: Color(0xFF4CAF50),
        emoji: '💚',
        isClean: true,
      );
      expect(_clean == otherModeClean, isFalse);
    });

    test('identical levels are equal and hash alike', () {
      const copy = TrackedLevel(
        value: 0,
        label: 'No Drinks',
        shortLabel: 'None',
        meaning: '0 alcoholic drinks',
        color: Color(0xFF4CAF50),
        emoji: '💚',
        isClean: true,
      );
      expect(_clean, copy);
      expect(_clean.hashCode, copy.hashCode);
    });
  });

  group('ModeDefinition', () {
    const mode = ModeDefinition(
      id: 'test_mode',
      name: 'Test Mode',
      emoji: '🧪',
      cleanDayLabel: 'Clean',
      levels: [_clean, _light],
      content: ContentPack(),
    );

    test('cleanLevel is the level flagged isClean', () {
      expect(mode.cleanLevel, _clean);
    });

    test('levelForValue resolves a persisted integer', () {
      expect(mode.levelForValue(1), _light);
    });

    test('levelForValue falls back to the clean level for unknown values', () {
      expect(mode.levelForValue(99), _clean);
    });

    test('copyWith replaces name and emoji only', () {
      final renamed = mode.copyWith(name: 'Renamed', emoji: '🎯');
      expect(renamed.name, 'Renamed');
      expect(renamed.emoji, '🎯');
      expect(renamed.id, 'test_mode');
      expect(renamed.levels, mode.levels);
    });
  });

  group('ContentPack', () {
    test('is empty by default and reports no facts or recovery', () {
      const pack = ContentPack();
      expect(pack.hasFacts, isFalse);
      expect(pack.hasRecovery, isFalse);
      expect(pack.achievements, isEmpty);
      expect(pack.motivations, isEmpty);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/tracked_level_test.dart`
Expected: FAIL — `Target of URI doesn't exist: 'package:dont_drink/core/models/tracked_level.dart'`.

- [ ] **Step 3: Write `tracked_level.dart`**

```dart
import 'package:flutter/material.dart';

/// One loggable status within a tracking mode.
///
/// The integer [value] is what gets persisted in the database, so a mode's
/// values must remain stable across releases. Value `0` is always the clean
/// day — the one that counts toward a streak.
@immutable
class TrackedLevel {
  const TrackedLevel({
    required this.value,
    required this.label,
    required this.shortLabel,
    required this.meaning,
    required this.color,
    required this.emoji,
    this.isClean = false,
  });

  /// Persisted integer code, unique within its mode.
  final int value;

  /// Full label, e.g. "1–2 Drinks".
  final String label;

  /// Compact label for tight spaces, e.g. "Light".
  final String shortLabel;

  /// Human description of what this level means.
  final String meaning;

  /// Calendar / chart color.
  final Color color;

  /// Emoji used in lists and notifications.
  final String emoji;

  /// True when this status counts toward a streak.
  final bool isClean;

  /// A readable foreground color that sits well on top of [color].
  ///
  /// The 0.4 threshold (rather than the usual 0.5) is deliberate: it keeps
  /// amber and orange on dark text, matching the palette the app shipped with.
  Color get onColor =>
      color.computeLuminance() > 0.4 ? Colors.black87 : Colors.white;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackedLevel && other.value == value && other.label == label;

  @override
  int get hashCode => Object.hash(value, label);
}
```

- [ ] **Step 4: Write `content_pack.dart`**

```dart
import 'package:dont_drink/core/models/achievement.dart';
import 'package:dont_drink/data/static/facts_data.dart';
import 'package:dont_drink/data/static/recovery_timeline_data.dart';
import 'package:flutter/foundation.dart';

/// The educational and motivational content belonging to one tracking mode.
///
/// Every list defaults to empty: a user-created custom mode has no facts and
/// no recovery timeline, and the UI hides those sections rather than showing
/// alcohol copy under a mode about something else.
@immutable
class ContentPack {
  const ContentPack({
    this.achievements = const [],
    this.facts = const [],
    this.recoveryMilestones = const [],
    this.motivations = const [],
    this.harmsTitle = 'Harms',
    this.benefitsTitle = 'Benefits',
    this.factsSubtitle = 'Harms & benefits',
    this.recoverySubtitle = 'What you gain over time',
  });

  final List<Achievement> achievements;
  final List<Fact> facts;
  final List<RecoveryMilestone> recoveryMilestones;
  final List<String> motivations;

  /// Section header for the "harm" half of the Facts screen.
  final String harmsTitle;

  /// Section header for the "benefit" half of the Facts screen.
  final String benefitsTitle;

  /// Subtitle for the Facts row on the More screen.
  final String factsSubtitle;

  /// Subtitle for the Recovery row on the More screen.
  final String recoverySubtitle;

  bool get hasFacts => facts.isNotEmpty;
  bool get hasRecovery => recoveryMilestones.isNotEmpty;

  List<Fact> get harms => facts.where((f) => f.isHarm).toList();
  List<Fact> get benefits => facts.where((f) => !f.isHarm).toList();

  /// Groups [recoveryMilestones] by tier, preserving order.
  Map<RecoveryTier, List<RecoveryMilestone>> get recoveryByTier => {
        for (final tier in RecoveryTier.values)
          tier: recoveryMilestones.where((m) => m.tier == tier).toList(),
      };
}
```

- [ ] **Step 5: Write `mode_definition.dart`**

```dart
import 'package:dont_drink/core/models/content_pack.dart';
import 'package:dont_drink/core/models/tracked_level.dart';
import 'package:flutter/foundation.dart';

/// One tracking mode: what is being tracked, how a day is logged, and the
/// content shown while tracking it.
///
/// Built-in modes are `const` definitions in `lib/data/static/modes/`. Custom
/// modes are built from `modes` table rows and have [isBuiltIn] false.
@immutable
class ModeDefinition {
  const ModeDefinition({
    required this.id,
    required this.name,
    required this.emoji,
    required this.cleanDayLabel,
    required this.levels,
    required this.content,
    this.isBuiltIn = true,
  });

  /// Stable identifier persisted in `day_entries.mode_id`.
  final String id;

  /// Display name, e.g. "Don't Drink".
  final String name;

  /// Shown beside the name in the switcher and settings list.
  final String emoji;

  /// How a clean day is described in stats copy, e.g. "Alcohol-free".
  final String cleanDayLabel;

  /// The scale a day is logged on. Exactly one level has `isClean: true`,
  /// and it has `value: 0`.
  final List<TrackedLevel> levels;

  final ContentPack content;

  final bool isBuiltIn;

  /// The level that counts toward a streak.
  TrackedLevel get cleanLevel => levels.firstWhere((l) => l.isClean);

  /// Resolve a persisted integer back to a level. Unknown values fall back to
  /// the clean level rather than throwing, so a corrupt row cannot crash the
  /// app.
  TrackedLevel levelForValue(int value) => levels.firstWhere(
        (l) => l.value == value,
        orElse: () => cleanLevel,
      );

  /// Only a custom mode's name and emoji are editable.
  ModeDefinition copyWith({String? name, String? emoji}) => ModeDefinition(
        id: id,
        name: name ?? this.name,
        emoji: emoji ?? this.emoji,
        cleanDayLabel: cleanDayLabel,
        levels: levels,
        content: content,
        isBuiltIn: isBuiltIn,
      );
}
```

- [ ] **Step 6: Run the test to verify it passes**

Run: `flutter test test/tracked_level_test.dart`
Expected: PASS — 9 tests.

- [ ] **Step 7: Verify analysis is clean**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add lib/core/models/tracked_level.dart lib/core/models/content_pack.dart lib/core/models/mode_definition.dart test/tracked_level_test.dart
git commit -m "feat: add TrackedLevel, ContentPack and ModeDefinition value types"
```

---

### Task 2: Don't Drink mode definition + registry

**Files:**
- Create: `lib/data/static/modes/dont_drink_mode.dart`
- Create: `lib/data/static/modes/mode_registry.dart`
- Test: `test/mode_registry_test.dart`

**Interfaces:**
- Consumes: `ModeDefinition`, `TrackedLevel`, `ContentPack` (Task 1); the existing `kAchievements`, `kAlcoholHarms`, `kBenefits`, `kRecoveryTimeline`, `kMotivations` consts.
- Produces:
  - `const ModeDefinition kDontDrinkMode` with `id: 'dont_drink'`.
  - `const List<ModeDefinition> kBuiltInModes` (Don't Drink only for now; Task 3 adds the rest).
  - `ModeDefinition? builtInModeById(String id)`.

**Note on content location:** Don't Drink's content lists stay in `facts_data.dart`, `achievements_data.dart`, `motivation_data.dart` and `recovery_timeline_data.dart` — those files remain the home of both the shared *types* (`Fact`, `Achievement`, `RecoveryMilestone`, `RecoveryTier`) and Don't Drink's *lists*. `dont_drink_mode.dart` references them. Other modes declare their own lists using the same types.

- [ ] **Step 1: Mode-prefix the existing achievement ids**

Modify `lib/data/static/achievements_data.dart` — change every `id:` value from `day_N` to `dont_drink.day_N`. There are nine: `day_1`, `day_3`, `day_7`, `day_14`, `day_30`, `day_60`, `day_90`, `day_180`, `day_365`.

```bash
sed -i "s/id: 'day_/id: 'dont_drink.day_/" lib/data/static/achievements_data.dart
grep -c "id: 'dont_drink.day_" lib/data/static/achievements_data.dart   # expect 9
```

Nothing persists these ids today, so no migration is needed.

- [ ] **Step 2: Write the failing test**

Create `test/mode_registry_test.dart`:

```dart
import 'package:dont_drink/data/static/modes/mode_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('built-in modes', () {
    test('every mode has exactly one clean level, at value 0', () {
      for (final mode in kBuiltInModes) {
        final clean = mode.levels.where((l) => l.isClean).toList();
        expect(clean.length, 1, reason: '${mode.id} must have one clean level');
        expect(clean.single.value, 0, reason: '${mode.id} clean level is 0');
      }
    });

    test('level values are unique and contiguous from 0', () {
      for (final mode in kBuiltInModes) {
        final values = mode.levels.map((l) => l.value).toList();
        expect(values.toSet().length, values.length,
            reason: '${mode.id} has duplicate level values');
        expect(values, List.generate(values.length, (i) => i),
            reason: '${mode.id} values must run 0..n-1 in order');
      }
    });

    test('mode ids are unique', () {
      final ids = kBuiltInModes.map((m) => m.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('achievement ids are globally unique across all modes', () {
      final ids = <String>[];
      for (final mode in kBuiltInModes) {
        ids.addAll(mode.content.achievements.map((a) => a.id));
      }
      expect(ids.toSet().length, ids.length,
          reason: 'achievement ids collide across modes');
    });

    test('achievement ids are prefixed with their mode id', () {
      for (final mode in kBuiltInModes) {
        for (final a in mode.content.achievements) {
          expect(a.id, startsWith('${mode.id}.'));
        }
      }
    });

    test("Don't Drink keeps its persisted level values", () {
      final mode = builtInModeById('dont_drink')!;
      expect(mode.levels.map((l) => l.label).toList(), [
        'No Drinks',
        '1–2 Drinks',
        '3–5 Drinks',
        '6+ Drinks',
        'Blackout',
      ]);
      expect(mode.levelForValue(4).shortLabel, 'Blackout');
      expect(mode.cleanLevel.value, 0);
    });

    test('builtInModeById returns null for an unknown id', () {
      expect(builtInModeById('nope'), isNull);
    });
  });
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `flutter test test/mode_registry_test.dart`
Expected: FAIL — `Target of URI doesn't exist: '.../mode_registry.dart'`.

- [ ] **Step 4: Write `dont_drink_mode.dart`**

```dart
import 'package:dont_drink/core/models/content_pack.dart';
import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/core/models/tracked_level.dart';
import 'package:dont_drink/data/static/achievements_data.dart';
import 'package:dont_drink/data/static/facts_data.dart';
import 'package:dont_drink/data/static/motivation_data.dart';
import 'package:dont_drink/data/static/recovery_timeline_data.dart';
import 'package:flutter/material.dart';

/// Don't Drink's level scale. These integers are what the app has persisted
/// since version 1 — they must not change.
const List<TrackedLevel> kDontDrinkLevels = [
  TrackedLevel(
    value: 0,
    label: 'No Drinks',
    shortLabel: 'None',
    meaning: '0 alcoholic drinks',
    color: Color(0xFF4CAF50), // Green
    emoji: '💚',
    isClean: true,
  ),
  TrackedLevel(
    value: 1,
    label: '1–2 Drinks',
    shortLabel: 'Light',
    meaning: 'Light drinking',
    color: Color(0xFFFFC107), // Yellow / Amber
    emoji: '🟡',
  ),
  TrackedLevel(
    value: 2,
    label: '3–5 Drinks',
    shortLabel: 'Moderate',
    meaning: 'Moderate drinking',
    color: Color(0xFFFF9800), // Orange
    emoji: '🟠',
  ),
  TrackedLevel(
    value: 3,
    label: '6+ Drinks',
    shortLabel: 'Heavy',
    meaning: 'Heavy drinking',
    color: Color(0xFFF44336), // Red
    emoji: '🔴',
  ),
  TrackedLevel(
    value: 4,
    label: 'Blackout',
    shortLabel: 'Blackout',
    meaning: 'Extreme drinking / memory loss',
    color: Color(0xFF000000), // Black
    emoji: '⚫',
  ),
];

const ModeDefinition kDontDrinkMode = ModeDefinition(
  id: 'dont_drink',
  name: "Don't Drink",
  emoji: '🍺',
  cleanDayLabel: 'Alcohol-free',
  levels: kDontDrinkLevels,
  content: ContentPack(
    achievements: kAchievements,
    facts: kAllFacts,
    recoveryMilestones: kRecoveryTimeline,
    motivations: kMotivations,
    harmsTitle: 'Alcohol Harms',
    benefitsTitle: 'Benefits of Not Drinking',
    factsSubtitle: 'Harms of alcohol & benefits of quitting',
    recoverySubtitle: 'What your body gains over time',
  ),
);
```

- [ ] **Step 5: Write `mode_registry.dart`**

```dart
import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/data/static/modes/dont_drink_mode.dart';

/// Every mode that ships with the app. Custom modes live in the database and
/// are appended by [ModeRepository] at runtime.
const List<ModeDefinition> kBuiltInModes = [
  kDontDrinkMode,
];

/// The default mode for a fresh install and the fallback whenever a stored
/// mode id cannot be resolved.
const ModeDefinition kDefaultMode = kDontDrinkMode;

/// Look up a built-in mode, or null if [id] names a custom mode or nothing.
ModeDefinition? builtInModeById(String id) {
  for (final mode in kBuiltInModes) {
    if (mode.id == id) return mode;
  }
  return null;
}
```

- [ ] **Step 6: Run the test to verify it passes**

Run: `flutter test test/mode_registry_test.dart`
Expected: PASS — 7 tests.

- [ ] **Step 7: Verify the whole suite and analysis still pass**

Run: `flutter test && flutter analyze`
Expected: all tests pass, `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add lib/data/static/modes/ lib/data/static/achievements_data.dart test/mode_registry_test.dart
git commit -m "feat: add Don't Drink mode definition and mode registry"
```

---

### Task 3: Don't Smoke, No Contact and Custom modes

**Files:**
- Create: `lib/data/static/modes/dont_smoke_mode.dart`
- Create: `lib/data/static/modes/no_contact_mode.dart`
- Create: `lib/data/static/modes/custom_mode.dart`
- Modify: `lib/data/static/modes/mode_registry.dart`
- Test: `test/mode_registry_test.dart` (existing invariants now cover three modes)

**Interfaces:**
- Consumes: everything from Tasks 1–2.
- Produces: `kDontSmokeMode`, `kNoContactMode`, `kCustomLevels`, `kCustomContentPack`, `ModeDefinition customModeFrom({required String id, required String name, required String emoji})`; `kBuiltInModes` grows to three entries.

- [ ] **Step 1: Add the new modes to the registry first (so the invariant tests fail)**

Modify `lib/data/static/modes/mode_registry.dart`:

```dart
import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/data/static/modes/dont_drink_mode.dart';
import 'package:dont_drink/data/static/modes/dont_smoke_mode.dart';
import 'package:dont_drink/data/static/modes/no_contact_mode.dart';

const List<ModeDefinition> kBuiltInModes = [
  kDontDrinkMode,
  kDontSmokeMode,
  kNoContactMode,
];
```

Leave `kDefaultMode` and `builtInModeById` as they are.

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/mode_registry_test.dart`
Expected: FAIL — `Target of URI doesn't exist: '.../dont_smoke_mode.dart'`.

- [ ] **Step 3: Write `dont_smoke_mode.dart`**

```dart
import 'package:dont_drink/core/models/achievement.dart';
import 'package:dont_drink/core/models/content_pack.dart';
import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/core/models/tracked_level.dart';
import 'package:dont_drink/data/static/facts_data.dart';
import 'package:dont_drink/data/static/recovery_timeline_data.dart';
import 'package:flutter/material.dart';

const List<TrackedLevel> kDontSmokeLevels = [
  TrackedLevel(
    value: 0,
    label: 'No Cigarettes',
    shortLabel: 'None',
    meaning: '0 cigarettes',
    color: Color(0xFF4CAF50),
    emoji: '💚',
    isClean: true,
  ),
  TrackedLevel(
    value: 1,
    label: '1–5 Cigarettes',
    shortLabel: 'Light',
    meaning: 'A few throughout the day',
    color: Color(0xFFFFC107),
    emoji: '🟡',
  ),
  TrackedLevel(
    value: 2,
    label: '6–15 Cigarettes',
    shortLabel: 'Moderate',
    meaning: 'Around half a pack',
    color: Color(0xFFFF9800),
    emoji: '🟠',
  ),
  TrackedLevel(
    value: 3,
    label: '16+ Cigarettes',
    shortLabel: 'Heavy',
    meaning: 'A pack or more',
    color: Color(0xFFF44336),
    emoji: '🔴',
  ),
  TrackedLevel(
    value: 4,
    label: 'Chain Smoking',
    shortLabel: 'Binge',
    meaning: 'Continuous, one after another',
    color: Color(0xFF000000),
    emoji: '⚫',
  ),
];

const List<Achievement> _achievements = [
  Achievement(
    id: 'dont_smoke.day_1',
    dayThreshold: 1,
    title: 'Carbon Monoxide Drops',
    description: 'Within a day your blood oxygen starts returning to normal.',
  ),
  Achievement(
    id: 'dont_smoke.day_3',
    dayThreshold: 3,
    title: 'Nicotine Cleared',
    description: 'Nicotine has left your body. Cravings peak and then fall.',
  ),
  Achievement(
    id: 'dont_smoke.day_7',
    dayThreshold: 7,
    title: 'Taste & Smell Return',
    description: 'Damaged nerve endings begin to recover within the week.',
  ),
  Achievement(
    id: 'dont_smoke.day_14',
    dayThreshold: 14,
    title: 'Easier Breathing',
    description: 'Lung function and circulation measurably improve.',
  ),
  Achievement(
    id: 'dont_smoke.day_30',
    dayThreshold: 30,
    title: 'One Month Smoke-Free',
    description: 'Coughing and shortness of breath keep decreasing.',
    emoji: '🌟',
    isLegendary: true,
  ),
  Achievement(
    id: 'dont_smoke.day_60',
    dayThreshold: 60,
    title: 'Cilia Regrowing',
    description: 'Your lungs are clearing themselves far more effectively.',
  ),
  Achievement(
    id: 'dont_smoke.day_90',
    dayThreshold: 90,
    title: 'New Lifestyle',
    description: 'Lung function can be up to 30% better than when you quit.',
    emoji: '✨',
    isLegendary: true,
  ),
  Achievement(
    id: 'dont_smoke.day_180',
    dayThreshold: 180,
    title: 'Half-Year Champion',
    description: 'Six months without a cigarette. Remarkable consistency.',
    emoji: '🥇',
    isLegendary: true,
  ),
  Achievement(
    id: 'dont_smoke.day_365',
    dayThreshold: 365,
    title: 'One Year Smoke-Free',
    description: 'Your risk of heart disease is now about half a smoker\'s.',
    emoji: '👑',
    isLegendary: true,
  ),
];

const List<Fact> _facts = [
  Fact(text: 'Smoking damages nearly every organ in the body.', isHarm: true),
  Fact(text: 'Tobacco smoke carries around 70 known carcinogens.', isHarm: true),
  Fact(text: 'Smoking narrows blood vessels and raises blood pressure.', isHarm: true),
  Fact(text: 'Smokers get respiratory infections more often.', isHarm: true),
  Fact(text: 'Smoking accelerates skin ageing and wrinkling.', isHarm: true),
  Fact(text: 'Nicotine dependence builds within days of regular use.', isHarm: true),
  Fact(text: 'Smoking slows wound healing after injury or surgery.', isHarm: true),
  Fact(text: 'Secondhand smoke harms the people around you.', isHarm: true),
  Fact(text: 'Smoking reduces stamina and athletic performance.', isHarm: true),
  Fact(text: 'Food tastes better again.', isHarm: false),
  Fact(text: 'Easier breathing and less coughing.', isHarm: false),
  Fact(text: 'Better circulation to hands and feet.', isHarm: false),
  Fact(text: 'Clothes, hair and home stop smelling of smoke.', isHarm: false),
  Fact(text: 'Significant money saved every week.', isHarm: false),
  Fact(text: 'Lower risk of heart attack and stroke.', isHarm: false),
  Fact(text: 'Improved fertility and pregnancy outcomes.', isHarm: false),
  Fact(text: 'Whiter teeth and healthier gums.', isHarm: false),
  Fact(text: 'More energy for exercise.', isHarm: false),
];

const List<RecoveryMilestone> _recovery = [
  RecoveryMilestone(
    afterHours: 12,
    tier: RecoveryTier.bronze,
    name: 'Oxygen Returns',
    label: '12 Hours',
    icon: Icons.air,
    benefits: [
      'Carbon monoxide in your blood drops to a normal level.',
      'Oxygen reaches your organs more effectively.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 72,
    tier: RecoveryTier.bronze,
    name: 'Nicotine Free',
    label: 'Day 3',
    icon: Icons.bolt_outlined,
    benefits: [
      'All nicotine has left your body.',
      'Cravings peak here and then begin to fade.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 24 * 14,
    tier: RecoveryTier.silver,
    name: 'Breathing Easier',
    label: 'Week 2',
    icon: Icons.favorite_outline,
    benefits: [
      'Circulation improves and walking becomes easier.',
      'Lung function begins to increase.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 24 * 90,
    tier: RecoveryTier.silver,
    name: 'Clearer Lungs',
    label: 'Month 3',
    icon: Icons.health_and_safety_outlined,
    benefits: [
      'Cilia regrow, clearing mucus and cutting infection risk.',
      'Coughing and shortness of breath decrease markedly.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 24 * 365,
    tier: RecoveryTier.gold,
    name: 'Halved Heart Risk',
    label: 'Year 1',
    icon: Icons.monitor_heart_outlined,
    benefits: [
      'Excess risk of coronary heart disease is about half a smoker\'s.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 24 * 365 * 5,
    tier: RecoveryTier.diamond,
    name: 'Stroke Risk Normalised',
    label: 'Year 5',
    icon: Icons.psychology_outlined,
    benefits: [
      'Stroke risk can fall to that of a non-smoker.',
      'Risk of mouth, throat and bladder cancer is halved.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 24 * 365 * 10,
    tier: RecoveryTier.diamond,
    name: 'Clean Slate',
    label: 'Year 10',
    icon: Icons.verified,
    benefits: [
      'Risk of dying from lung cancer is about half that of a smoker.',
    ],
  ),
];

const List<String> _motivations = [
  'Every smoke-free day is progress.',
  'The craving passes whether you smoke or not.',
  'Your lungs are already repairing themselves.',
  'You are not giving something up — you are getting something back.',
  'One day at a time is still moving forward.',
  'Breathe. That feeling is your body recovering.',
  'Nobody ever regretted the cigarette they did not smoke.',
  'Small daily choices. Big long-term changes.',
  'Discomfort is temporary. Pride lasts.',
  'You did not come this far to only come this far.',
];

const ModeDefinition kDontSmokeMode = ModeDefinition(
  id: 'dont_smoke',
  name: "Don't Smoke",
  emoji: '🚭',
  cleanDayLabel: 'Smoke-free',
  levels: kDontSmokeLevels,
  content: ContentPack(
    achievements: _achievements,
    facts: _facts,
    recoveryMilestones: _recovery,
    motivations: _motivations,
    harmsTitle: 'Smoking Harms',
    benefitsTitle: 'Benefits of Quitting',
    factsSubtitle: 'Harms of smoking & benefits of quitting',
    recoverySubtitle: 'What your lungs gain over time',
  ),
);
```

- [ ] **Step 4: Write `no_contact_mode.dart`**

Note this mode has **four** levels, not five.

```dart
import 'package:dont_drink/core/models/achievement.dart';
import 'package:dont_drink/core/models/content_pack.dart';
import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/core/models/tracked_level.dart';
import 'package:dont_drink/data/static/facts_data.dart';
import 'package:dont_drink/data/static/recovery_timeline_data.dart';
import 'package:flutter/material.dart';

const List<TrackedLevel> kNoContactLevels = [
  TrackedLevel(
    value: 0,
    label: 'No Contact',
    shortLabel: 'Clean',
    meaning: 'A full day with no contact',
    color: Color(0xFF4CAF50),
    emoji: '💚',
    isClean: true,
  ),
  TrackedLevel(
    value: 1,
    label: 'Thought About It',
    shortLabel: 'Urge',
    meaning: 'The urge came, you did not act on it',
    color: Color(0xFFFFC107),
    emoji: '🟡',
  ),
  TrackedLevel(
    value: 2,
    label: 'Checked Their Profile',
    shortLabel: 'Checked',
    meaning: 'Looked them up without reaching out',
    color: Color(0xFFFF9800),
    emoji: '🟠',
  ),
  TrackedLevel(
    value: 3,
    label: 'Reached Out',
    shortLabel: 'Contact',
    meaning: 'Messaged, called, or met up',
    color: Color(0xFFF44336),
    emoji: '🔴',
  ),
];

const List<Achievement> _achievements = [
  Achievement(
    id: 'no_contact.day_1',
    dayThreshold: 1,
    title: 'The Decision',
    description: 'The hardest day is the one you have already finished.',
  ),
  Achievement(
    id: 'no_contact.day_3',
    dayThreshold: 3,
    title: 'Through the Peak',
    description: 'The urge is at its loudest around now — and you held.',
  ),
  Achievement(
    id: 'no_contact.day_7',
    dayThreshold: 7,
    title: 'One Week Clear',
    description: 'A full week of choosing your own peace.',
  ),
  Achievement(
    id: 'no_contact.day_14',
    dayThreshold: 14,
    title: 'Quieter Mind',
    description: 'The constant checking impulse starts to loosen its grip.',
  ),
  Achievement(
    id: 'no_contact.day_30',
    dayThreshold: 30,
    title: 'One Month Strong',
    description: 'Thirty days. Your days belong to you again.',
    emoji: '🌟',
    isLegendary: true,
  ),
  Achievement(
    id: 'no_contact.day_60',
    dayThreshold: 60,
    title: 'Clearer Perspective',
    description: 'Distance makes the situation far easier to see honestly.',
  ),
  Achievement(
    id: 'no_contact.day_90',
    dayThreshold: 90,
    title: 'New Normal',
    description: 'After 90 days, no contact stops feeling like an effort.',
    emoji: '✨',
    isLegendary: true,
  ),
  Achievement(
    id: 'no_contact.day_180',
    dayThreshold: 180,
    title: 'Half-Year Free',
    description: 'Six months of protecting your own wellbeing.',
    emoji: '🥇',
    isLegendary: true,
  ),
  Achievement(
    id: 'no_contact.day_365',
    dayThreshold: 365,
    title: 'One Year Free',
    description: 'A full year. You built a life that does not need them in it.',
    emoji: '👑',
    isLegendary: true,
  ),
];

const List<Fact> _facts = [
  Fact(text: 'Every check-in restarts the attachment cycle.', isHarm: true),
  Fact(text: 'Intermittent contact is the hardest pattern to let go of.', isHarm: true),
  Fact(text: 'Rumination keeps the stress response switched on.', isHarm: true),
  Fact(text: 'Checking their profile delays your own recovery.', isHarm: true),
  Fact(text: '"Just one message" usually resets the clock entirely.', isHarm: true),
  Fact(text: 'Hoping for closure from them keeps you waiting on them.', isHarm: true),
  Fact(text: 'Sleep and concentration suffer while the loop continues.', isHarm: true),
  Fact(text: 'The urge peaks and then passes — always.', isHarm: false),
  Fact(text: 'Emotional intensity fades a little more each week.', isHarm: false),
  Fact(text: 'Your attention returns to your own life.', isHarm: false),
  Fact(text: 'Sleep and appetite settle back down.', isHarm: false),
  Fact(text: 'Other relationships get the energy they deserve.', isHarm: false),
  Fact(text: 'Self-respect rebuilds with every day you hold.', isHarm: false),
  Fact(text: 'Clarity about what happened arrives with distance.', isHarm: false),
  Fact(text: 'You stop rehearsing conversations that never happen.', isHarm: false),
];

const List<RecoveryMilestone> _recovery = [
  RecoveryMilestone(
    afterHours: 24,
    tier: RecoveryTier.bronze,
    name: 'The Decision',
    label: 'Day 1',
    icon: Icons.flag_outlined,
    benefits: [
      'The loop is broken. Today is the first day it does not continue.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 72,
    tier: RecoveryTier.bronze,
    name: 'The Peak',
    label: 'Day 3',
    icon: Icons.trending_down,
    benefits: [
      'Urges are usually strongest around now.',
      'From here the intensity starts to fall.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 24 * 21,
    tier: RecoveryTier.silver,
    name: 'The Quiet',
    label: 'Week 3',
    icon: Icons.self_improvement,
    benefits: [
      'The impulse to check becomes noticeably less frequent.',
      'Sleep and concentration begin to settle.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 24 * 90,
    tier: RecoveryTier.silver,
    name: 'Perspective',
    label: 'Month 3',
    icon: Icons.visibility_outlined,
    benefits: [
      'Distance makes it far easier to see the situation clearly.',
      'Your own plans start filling the space.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 24 * 365,
    tier: RecoveryTier.gold,
    name: 'Your Own Life',
    label: 'Year 1',
    icon: Icons.wb_sunny_outlined,
    benefits: [
      'A year of days that were about you.',
    ],
  ),
  RecoveryMilestone(
    afterHours: 24 * 365 * 2,
    tier: RecoveryTier.diamond,
    name: 'Closed Chapter',
    label: 'Year 2',
    icon: Icons.verified,
    benefits: [
      'The memory stops steering your decisions.',
    ],
  ),
];

const List<String> _motivations = [
  'The urge passes. You do not have to act on it.',
  'No contact is not punishment. It is protection.',
  'You do not need closure from someone who caused the wound.',
  'Checking sets the clock back. Not checking moves it forward.',
  'Your peace is worth more than the answer you want.',
  'Small daily choices. Big long-term changes.',
  'One day at a time is still moving forward.',
  'You are allowed to stop waiting.',
  'Discomfort is temporary. Pride lasts.',
  'You did not come this far to only come this far.',
];

const ModeDefinition kNoContactMode = ModeDefinition(
  id: 'no_contact',
  name: 'No Contact',
  emoji: '📵',
  cleanDayLabel: 'No-contact',
  levels: kNoContactLevels,
  content: ContentPack(
    achievements: _achievements,
    facts: _facts,
    recoveryMilestones: _recovery,
    motivations: _motivations,
    harmsTitle: 'Why Contact Hurts',
    benefitsTitle: 'Benefits of No Contact',
    factsSubtitle: 'Why contact hurts & what distance gives back',
    recoverySubtitle: 'What changes as the distance grows',
  ),
);
```

- [ ] **Step 5: Write `custom_mode.dart`**

Custom modes have **three** levels and no facts or recovery timeline.

```dart
import 'package:dont_drink/core/models/achievement.dart';
import 'package:dont_drink/core/models/content_pack.dart';
import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/core/models/tracked_level.dart';
import 'package:flutter/material.dart';

/// The fixed scale every custom mode uses. There is no level editor.
const List<TrackedLevel> kCustomLevels = [
  TrackedLevel(
    value: 0,
    label: 'Clean Day',
    shortLabel: 'Clean',
    meaning: 'You held to it today',
    color: Color(0xFF4CAF50),
    emoji: '💚',
    isClean: true,
  ),
  TrackedLevel(
    value: 1,
    label: 'Slip',
    shortLabel: 'Slip',
    meaning: 'A small lapse, back on track',
    color: Color(0xFFFFC107),
    emoji: '🟡',
  ),
  TrackedLevel(
    value: 2,
    label: 'Relapse',
    shortLabel: 'Relapse',
    meaning: 'A full return to the habit',
    color: Color(0xFFF44336),
    emoji: '🔴',
  ),
];

/// Habit-neutral milestones. Ids are prefixed per mode by [customModeFrom].
const List<Achievement> _genericAchievements = [
  Achievement(
    id: 'day_1',
    dayThreshold: 1,
    title: 'First Day Down',
    description: 'The first day is the hardest one to start.',
  ),
  Achievement(
    id: 'day_3',
    dayThreshold: 3,
    title: 'Three Days In',
    description: 'Early urges usually peak around here — and you held.',
  ),
  Achievement(
    id: 'day_7',
    dayThreshold: 7,
    title: 'One Week Strong',
    description: 'A full week of choosing the harder right thing.',
  ),
  Achievement(
    id: 'day_14',
    dayThreshold: 14,
    title: 'Two Weeks',
    description: 'Long enough that the new pattern starts to feel real.',
  ),
  Achievement(
    id: 'day_30',
    dayThreshold: 30,
    title: 'One Month Strong',
    description: 'Thirty days of consistency. That is a real change.',
    emoji: '🌟',
    isLegendary: true,
  ),
  Achievement(
    id: 'day_60',
    dayThreshold: 60,
    title: 'Two Months',
    description: 'The effort required keeps dropping.',
  ),
  Achievement(
    id: 'day_90',
    dayThreshold: 90,
    title: 'New Lifestyle',
    description: 'Habits become much easier to maintain after 90 days.',
    emoji: '✨',
    isLegendary: true,
  ),
  Achievement(
    id: 'day_180',
    dayThreshold: 180,
    title: 'Half-Year Champion',
    description: 'Six months of choosing yourself. Remarkable consistency.',
    emoji: '🥇',
    isLegendary: true,
  ),
  Achievement(
    id: 'day_365',
    dayThreshold: 365,
    title: 'One Full Year',
    description: 'A legendary achievement. One full year of better days.',
    emoji: '👑',
    isLegendary: true,
  ),
];

const List<String> _genericMotivations = [
  'Every clean day is progress.',
  "Your future self benefits from today's decision.",
  'Streaks are built one day at a time.',
  'Progress matters more than perfection.',
  'You are stronger than a craving.',
  'Small daily choices. Big long-term changes.',
  'One day at a time is still moving forward.',
  'The best project you can work on is you.',
  'Discomfort is temporary. Pride lasts.',
  'You did not come this far to only come this far.',
];

/// Build a custom mode from its stored row.
///
/// Achievement ids are prefixed with [id] so they stay globally unique even
/// when several custom modes exist.
ModeDefinition customModeFrom({
  required String id,
  required String name,
  required String emoji,
}) {
  return ModeDefinition(
    id: id,
    name: name,
    emoji: emoji,
    cleanDayLabel: 'Clean',
    levels: kCustomLevels,
    isBuiltIn: false,
    content: ContentPack(
      achievements: [
        for (final a in _genericAchievements)
          Achievement(
            id: '$id.${a.id}',
            dayThreshold: a.dayThreshold,
            title: a.title,
            description: a.description,
            emoji: a.emoji,
            isLegendary: a.isLegendary,
          ),
      ],
      motivations: _genericMotivations,
      // No facts, no recovery timeline — the UI hides those sections.
    ),
  );
}
```

- [ ] **Step 6: Add a custom-mode test to `test/mode_registry_test.dart`**

Append inside `main()`:

```dart
  group('custom modes', () {
    test('use the three-level template and have no facts or recovery', () {
      final mode = customModeFrom(id: 'custom_1', name: 'My Mode', emoji: '🎯');
      expect(mode.levels.length, 3);
      expect(mode.isBuiltIn, isFalse);
      expect(mode.cleanLevel.value, 0);
      expect(mode.content.hasFacts, isFalse);
      expect(mode.content.hasRecovery, isFalse);
      expect(mode.content.motivations, isNotEmpty);
    });

    test('prefix their achievement ids with the mode id', () {
      final mode = customModeFrom(id: 'custom_1', name: 'My Mode', emoji: '🎯');
      expect(mode.content.achievements.first.id, 'custom_1.day_1');
      for (final a in mode.content.achievements) {
        expect(a.id, startsWith('custom_1.'));
      }
    });

    test('two custom modes do not share achievement ids', () {
      final a = customModeFrom(id: 'custom_1', name: 'A', emoji: '🎯');
      final b = customModeFrom(id: 'custom_2', name: 'B', emoji: '🎲');
      final ids = {
        ...a.content.achievements.map((x) => x.id),
        ...b.content.achievements.map((x) => x.id),
      };
      expect(ids.length,
          a.content.achievements.length + b.content.achievements.length);
    });
  });
```

Add the import at the top of the file:

```dart
import 'package:dont_drink/data/static/modes/custom_mode.dart';
```

- [ ] **Step 7: Run the tests to verify they pass**

Run: `flutter test test/mode_registry_test.dart`
Expected: PASS — 10 tests. The invariant tests from Task 2 now run against all three built-in modes, confirming No Contact's four-level scale still satisfies "one clean level at value 0" and "values 0..n-1".

- [ ] **Step 8: Verify the whole suite and analysis**

Run: `flutter test && flutter analyze`
Expected: all pass, `No issues found!`

- [ ] **Step 9: Commit**

```bash
git add lib/data/static/modes/ test/mode_registry_test.dart
git commit -m "feat: add Don't Smoke, No Contact and Custom mode definitions"
```

---

### Task 4: Database schema v2 — mode_id column and modes table

**Files:**
- Modify: `lib/data/database/app_database.dart`
- Modify: `lib/core/models/day_entry.dart` (add `modeId`; level stays `DrinkLevel` for now)
- Modify: `lib/data/repositories/entry_repository.dart` (scope queries by mode id)
- Modify: `lib/viewmodels/tracker_viewmodel.dart` (pass `'dont_drink'` through)
- Modify: `lib/services/export_import_service.dart` (`DayEntry.fromMap` call site)
- Modify: `pubspec.yaml` (add `sqflite_common_ffi` dev dependency)
- Test: `test/migration_test.dart` (new), `test/stats_service_test.dart` (its `_entry` helper gains `modeId`)

**Why the level type does not change yet:** swapping `DrinkLevel` for `TrackedLevel` breaks every UI file at once. This task keeps `DrinkLevel` so the migration lands, and is verified, on its own. Task 6 does the type swap.

**Interfaces:**
- Consumes: `kDefaultMode` from `mode_registry.dart`.
- Produces:
  - `AppDatabase.tableModes == 'modes'`, schema version 2.
  - `DayEntry({required String modeId, required DateTime date, required DrinkLevel level, String? note, DateTime? updatedAt})`; `toMap()` now emits `mode_id`.
  - `EntryRepository` methods gain a leading `String modeId` parameter: `delete(String modeId, DateTime date)`, `getForDate(String modeId, DateTime date)`, `getAll(String modeId)`, `getRange(String modeId, DateTime start, DateTime end)`, `getMonth(String modeId, DateTime month)`, `levelCounts(String modeId)`, plus new `deleteAllForMode(String modeId)`.

- [ ] **Step 1: Add the test-only database dependency**

Modify `pubspec.yaml` under `dev_dependencies:`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_launcher_icons: ^0.14.3

  # Runs a real SQLite database on the host so migrations can be tested.
  sqflite_common_ffi: ^2.3.4
```

Run: `flutter pub get`

> **Watch the SDK path.** `pub get` can rewrite `android/local.properties`'s `sdk.dir` to `/opt/android-sdk`. If it does, set it back to `/home/ben/Android/Sdk` — the `/opt` SDK has no NDK and no accepted licenses.

- [ ] **Step 2: Write the failing test**

Create `test/migration_test.dart`:

```dart
import 'dart:io';

import 'package:dont_drink/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('dontdrink_migration');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  /// A fresh on-disk path. An in-memory database would be destroyed the moment
  /// the v1 connection closes, so the migration would have nothing to migrate.
  String newDbPath() => p.join(tempDir.path, 'test_${DateTime.now().microsecondsSinceEpoch}.db');

  /// Build a database with the exact v1 schema the app shipped with.
  Future<Database> openV1(String path) async {
    return databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) async {
          await db.execute('''
            CREATE TABLE day_entries (
              date_key   TEXT PRIMARY KEY,
              level      INTEGER NOT NULL,
              note       TEXT,
              updated_at INTEGER NOT NULL
            )
          ''');
        },
      ),
    );
  }

  test('v1 rows are assigned to dont_drink and keep their values', () async {
    final path = newDbPath();

    final v1 = await openV1(path);
    await v1.insert('day_entries', {
      'date_key': '2026-06-01',
      'level': 0,
      'note': 'felt good',
      'updated_at': 1750000000000,
    });
    await v1.insert('day_entries', {
      'date_key': '2026-06-02',
      'level': 3,
      'note': null,
      'updated_at': 1750000100000,
    });
    await v1.close();

    final v2 = await AppDatabase.openAt(path);
    final rows = await v2.query('day_entries', orderBy: 'date_key ASC');

    expect(rows.length, 2);
    expect(rows[0]['mode_id'], 'dont_drink');
    expect(rows[0]['date_key'], '2026-06-01');
    expect(rows[0]['level'], 0);
    expect(rows[0]['note'], 'felt good');
    expect(rows[0]['updated_at'], 1750000000000);
    expect(rows[1]['mode_id'], 'dont_drink');
    expect(rows[1]['level'], 3);
    await v2.close();
  });

  test('after migration the primary key is (mode_id, date_key)', () async {
    final path = newDbPath();

    final v1 = await openV1(path);
    await v1.insert('day_entries', {
      'date_key': '2026-06-01',
      'level': 0,
      'note': null,
      'updated_at': 1750000000000,
    });
    await v1.close();

    final v2 = await AppDatabase.openAt(path);

    // The same date in another mode must coexist, not replace.
    await v2.insert('day_entries', {
      'mode_id': 'dont_smoke',
      'date_key': '2026-06-01',
      'level': 2,
      'note': null,
      'updated_at': 1750000200000,
    });
    final all = await v2.query('day_entries');
    expect(all.length, 2);

    // The same (mode, date) must still collide.
    await v2.insert(
      'day_entries',
      {
        'mode_id': 'dont_smoke',
        'date_key': '2026-06-01',
        'level': 4,
        'note': null,
        'updated_at': 1750000300000,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    final after = await v2.query('day_entries');
    expect(after.length, 2);
    expect(
      after.firstWhere((r) => r['mode_id'] == 'dont_smoke')['level'],
      4,
    );
    await v2.close();
  });

  test('the modes table exists after migration', () async {
    final path = newDbPath();
    final v1 = await openV1(path);
    await v1.close();

    final v2 = await AppDatabase.openAt(path);
    await v2.insert('modes', {
      'id': 'custom_1',
      'name': 'My Mode',
      'emoji': '🎯',
      'created_at': 1750000000000,
    });
    expect((await v2.query('modes')).length, 1);
    await v2.close();
  });

  test('a fresh install creates both tables at v2', () async {
    final db = await AppDatabase.openAt(newDbPath());
    expect(await db.getVersion(), 2);
    await db.insert('day_entries', {
      'mode_id': 'dont_drink',
      'date_key': '2026-06-01',
      'level': 0,
      'note': null,
      'updated_at': 1750000000000,
    });
    expect((await db.query('day_entries')).length, 1);
    expect((await db.query('modes')).length, 0);
    await db.close();
  });
}
```

- [ ] **Step 3: Run the test to verify it fails**

Run: `flutter test test/migration_test.dart`
Expected: FAIL — `The method 'openAt' isn't defined for the type 'AppDatabase'`.

- [ ] **Step 4: Rewrite `app_database.dart`**

```dart
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Owns the SQLite connection and schema. Local-only; nothing leaves the device.
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const String _dbName = 'dont_drink.db';
  static const int _dbVersion = 2;

  /// Table holding one row per logged calendar day, per mode.
  static const String tableEntries = 'day_entries';

  /// Table holding user-created custom modes. Built-in modes are const in
  /// code and never appear here.
  static const String tableModes = 'modes';

  Database? _db;

  Future<Database> get database async {
    return _db ??= await _open();
  }

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openAt(p.join(dir, _dbName));
  }

  /// Open (and migrate) the database at [path]. Exposed so tests can drive the
  /// real schema and migration against a temporary file.
  static Future<Database> openAt(String path) {
    return databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute(_createEntriesSql(tableEntries));
    await db.execute(_createModesSql);
  }

  static Future<void> _onUpgrade(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _migrateToV2(db);
    }
  }

  /// v1 → v2: every existing row belongs to Don't Drink, and the primary key
  /// becomes (mode_id, date_key).
  ///
  /// SQLite cannot add a primary key with ALTER TABLE, so the table is rebuilt.
  /// The whole rebuild runs in one transaction: either the user ends up on v2
  /// with all their data, or nothing changes.
  static Future<void> _migrateToV2(Database db) async {
    await db.transaction((txn) async {
      await txn.execute(_createEntriesSql('${tableEntries}_new'));
      await txn.execute('''
        INSERT INTO ${tableEntries}_new (mode_id, date_key, level, note, updated_at)
        SELECT 'dont_drink', date_key, level, note, updated_at FROM $tableEntries
      ''');
      await txn.execute('DROP TABLE $tableEntries');
      await txn.execute(
          'ALTER TABLE ${tableEntries}_new RENAME TO $tableEntries');
      await txn.execute(_createModesSql);
    });
  }

  static String _createEntriesSql(String table) => '''
      CREATE TABLE $table (
        mode_id    TEXT NOT NULL,
        date_key   TEXT NOT NULL,
        level      INTEGER NOT NULL,
        note       TEXT,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (mode_id, date_key)
      )
    ''';

  static const String _createModesSql = '''
      CREATE TABLE $tableModes (
        id         TEXT PRIMARY KEY,
        name       TEXT NOT NULL,
        emoji      TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''';

  /// Test/maintenance helper: closes the underlying connection.
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
```

- [ ] **Step 5: Run the migration test to verify it passes**

Run: `flutter test test/migration_test.dart`
Expected: PASS — 4 tests.

- [ ] **Step 6: Add `modeId` to `DayEntry`**

Modify `lib/core/models/day_entry.dart`:

```dart
import 'package:dont_drink/core/models/drink_level.dart';
import 'package:dont_drink/core/utils/date_utils.dart';

/// A single logged day. Exactly one entry can exist per calendar date per mode.
class DayEntry {
  DayEntry({
    required this.modeId,
    required this.date,
    required this.level,
    this.note,
    this.updatedAt,
  });

  /// Which tracking mode this entry belongs to.
  final String modeId;

  /// The calendar day this entry belongs to (time component is ignored).
  final DateTime date;

  /// The status logged for [date].
  final DrinkLevel level;

  /// Optional free-text note.
  final String? note;

  /// When this entry was last saved.
  final DateTime? updatedAt;

  /// Date key in `yyyy-MM-dd` form — half of the composite primary key.
  String get dateKey => DateOnly.keyFor(date);

  DayEntry copyWith({
    String? modeId,
    DateTime? date,
    DrinkLevel? level,
    String? note,
    DateTime? updatedAt,
  }) {
    return DayEntry(
      modeId: modeId ?? this.modeId,
      date: date ?? this.date,
      level: level ?? this.level,
      note: note ?? this.note,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'mode_id': modeId,
      'date_key': dateKey,
      'level': level.value,
      'note': note,
      'updated_at': (updatedAt ?? DateTime.now()).millisecondsSinceEpoch,
    };
  }

  factory DayEntry.fromMap(Map<String, Object?> map) {
    return DayEntry(
      modeId: map['mode_id'] as String? ?? 'dont_drink',
      date: DateOnly.parseKey(map['date_key'] as String),
      level: DrinkLevel.fromValue(map['level'] as int),
      note: map['note'] as String?,
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
}
```

- [ ] **Step 7: Scope `EntryRepository` by mode**

Modify `lib/data/repositories/entry_repository.dart` — every read and delete gains `mode_id = ?`:

```dart
  /// Remove the entry for [date] in [modeId], if any (clears the day).
  Future<void> delete(String modeId, DateTime date) async {
    final db = await _appDb.database;
    await db.delete(
      AppDatabase.tableEntries,
      where: 'mode_id = ? AND date_key = ?',
      whereArgs: [modeId, DateOnly.keyFor(date)],
    );
  }

  /// The entry for [date] in [modeId], or null if the day has not been logged.
  Future<DayEntry?> getForDate(String modeId, DateTime date) async {
    final db = await _appDb.database;
    final rows = await db.query(
      AppDatabase.tableEntries,
      where: 'mode_id = ? AND date_key = ?',
      whereArgs: [modeId, DateOnly.keyFor(date)],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DayEntry.fromMap(rows.first);
  }

  /// All entries for [modeId], ordered oldest-first.
  Future<List<DayEntry>> getAll(String modeId) async {
    final db = await _appDb.database;
    final rows = await db.query(
      AppDatabase.tableEntries,
      where: 'mode_id = ?',
      whereArgs: [modeId],
      orderBy: 'date_key ASC',
    );
    return rows.map(DayEntry.fromMap).toList();
  }

  /// All entries for [modeId] within the inclusive range, keyed by date.
  Future<Map<String, DayEntry>> getRange(
      String modeId, DateTime start, DateTime end) async {
    final db = await _appDb.database;
    final rows = await db.query(
      AppDatabase.tableEntries,
      where: 'mode_id = ? AND date_key BETWEEN ? AND ?',
      whereArgs: [modeId, DateOnly.keyFor(start), DateOnly.keyFor(end)],
    );
    return {
      for (final row in rows)
        row['date_key'] as String: DayEntry.fromMap(row),
    };
  }

  /// All entries for [modeId] in the month containing [month], keyed by date.
  Future<Map<String, DayEntry>> getMonth(String modeId, DateTime month) {
    return getRange(
        modeId, DateOnly.firstOfMonth(month), DateOnly.lastOfMonth(month));
  }

  /// Count of entries grouped by level across [modeId]'s whole history.
  Future<Map<DrinkLevel, int>> levelCounts(String modeId) async {
    final entries = await getAll(modeId);
    final counts = {for (final level in DrinkLevel.values) level: 0};
    for (final entry in entries) {
      counts[entry.level] = (counts[entry.level] ?? 0) + 1;
    }
    return counts;
  }

  /// Delete every entry belonging to [modeId]. Used when a custom mode is
  /// deleted.
  Future<void> deleteAllForMode(String modeId) async {
    final db = await _appDb.database;
    await db.delete(
      AppDatabase.tableEntries,
      where: 'mode_id = ?',
      whereArgs: [modeId],
    );
  }
```

`upsert(DayEntry entry)` is unchanged — the entry already carries its `modeId` through `toMap()`.

- [ ] **Step 8: Fix the two remaining call sites**

In `lib/viewmodels/tracker_viewmodel.dart`, pass the Don't Drink id through (Task 7 replaces this with the real active mode):

- `load()`: `final all = await _repo.getAll('dont_drink');`
- `logDay()`: construct with `DayEntry(modeId: 'dont_drink', date: ..., level: level, note: note)`
- `clearDay()`: `await _repo.delete('dont_drink', date);`

In `lib/services/export_import_service.dart`, `DayEntry.fromMap` already defaults a missing `mode_id` to `dont_drink`, so no change is needed there yet.

- [ ] **Step 9: Run the whole suite and analysis**

Run: `flutter test && flutter analyze`
Expected: all tests pass (`stats_service_test.dart` still compiles — `DayEntry` gained a required `modeId`, so update its `_entry` helper to `DayEntry(modeId: 'dont_drink', date: date, level: level)`), `No issues found!`

- [ ] **Step 10: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/data/database/app_database.dart lib/core/models/day_entry.dart lib/data/repositories/entry_repository.dart lib/viewmodels/tracker_viewmodel.dart test/migration_test.dart test/stats_service_test.dart
git commit -m "feat: add mode_id column, modes table and v1->v2 migration"
```

---

### Task 5: ModeRepository

**Files:**
- Create: `lib/data/repositories/mode_repository.dart`
- Test: `test/mode_repository_test.dart`

**Interfaces:**
- Consumes: `AppDatabase.tableModes`, `kBuiltInModes`, `kDefaultMode`, `builtInModeById`, `customModeFrom`, `EntryRepository.deleteAllForMode`.
- Produces `ModeRepository` with:
  - `Future<List<ModeDefinition>> customModes()`
  - `Future<List<ModeDefinition>> allModes()` — built-ins then customs
  - `Future<ModeDefinition> createCustom({required String name, required String emoji})`
  - `Future<void> updateCustom(String id, {required String name, required String emoji})`
  - `Future<void> deleteCustom(String id)` — drops the mode and its entries
  - `Future<List<String>> enabledModeIds()` — defaults to `['dont_drink']`
  - `Future<void> setEnabledModeIds(List<String> ids)`
  - `Future<String> activeModeId()` — defaults to `'dont_drink'`
  - `Future<void> setActiveModeId(String id)`
  - `Future<ModeDefinition> resolveActiveMode()` — falls back to `kDefaultMode`

- [ ] **Step 1: Write the failing test**

Create `test/mode_repository_test.dart`:

```dart
import 'package:dont_drink/data/repositories/mode_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('a fresh install enables and activates Don\'t Drink', () async {
    final repo = ModeRepository();
    expect(await repo.enabledModeIds(), ['dont_drink']);
    expect(await repo.activeModeId(), 'dont_drink');
    expect((await repo.resolveActiveMode()).id, 'dont_drink');
  });

  test('createCustom stores a mode and returns it', () async {
    final repo = ModeRepository();
    final mode = await repo.createCustom(name: 'No Sugar', emoji: '🍭');

    expect(mode.id, startsWith('custom_'));
    expect(mode.name, 'No Sugar');
    expect(mode.emoji, '🍭');
    expect(mode.isBuiltIn, isFalse);
    expect(mode.levels.length, 3);

    final stored = await repo.customModes();
    expect(stored.map((m) => m.id), [mode.id]);
  });

  test('allModes lists built-ins then customs', () async {
    final repo = ModeRepository();
    await repo.createCustom(name: 'No Sugar', emoji: '🍭');
    final all = await repo.allModes();
    expect(all.take(3).map((m) => m.id),
        ['dont_drink', 'dont_smoke', 'no_contact']);
    expect(all.last.name, 'No Sugar');
  });

  test('updateCustom renames without changing the id', () async {
    final repo = ModeRepository();
    final mode = await repo.createCustom(name: 'Old', emoji: '🎯');
    await repo.updateCustom(mode.id, name: 'New', emoji: '🎲');
    final stored = (await repo.customModes()).single;
    expect(stored.id, mode.id);
    expect(stored.name, 'New');
    expect(stored.emoji, '🎲');
  });

  test('deleteCustom removes the mode and drops it from enabled ids', () async {
    final repo = ModeRepository();
    final mode = await repo.createCustom(name: 'Temp', emoji: '🎯');
    await repo.setEnabledModeIds(['dont_drink', mode.id]);

    await repo.deleteCustom(mode.id);

    expect(await repo.customModes(), isEmpty);
    expect(await repo.enabledModeIds(), ['dont_drink']);
  });

  test('resolveActiveMode falls back when the stored id is gone', () async {
    final repo = ModeRepository();
    await repo.setActiveModeId('custom_deleted');
    expect((await repo.resolveActiveMode()).id, 'dont_drink');
  });

  test('enabled and active ids round-trip', () async {
    final repo = ModeRepository();
    await repo.setEnabledModeIds(['dont_drink', 'no_contact']);
    await repo.setActiveModeId('no_contact');
    expect(await repo.enabledModeIds(), ['dont_drink', 'no_contact']);
    expect((await repo.resolveActiveMode()).id, 'no_contact');
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/mode_repository_test.dart`
Expected: FAIL — `Target of URI doesn't exist: '.../mode_repository.dart'`.

- [ ] **Step 3: Write `mode_repository.dart`**

```dart
import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/data/database/app_database.dart';
import 'package:dont_drink/data/repositories/entry_repository.dart';
import 'package:dont_drink/data/static/modes/custom_mode.dart';
import 'package:dont_drink/data/static/modes/mode_registry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Owns which modes exist, which are enabled, and which one is active.
///
/// Built-in modes are `const` in code; only user-created custom modes are
/// stored in the `modes` table. Enabled/active selection lives in
/// [SharedPreferences] alongside the other lightweight preferences.
class ModeRepository {
  ModeRepository({AppDatabase? db, EntryRepository? entries})
      : _appDb = db ?? AppDatabase.instance,
        _entries = entries ?? EntryRepository();

  static const _kEnabledModeIds = 'enabled_mode_ids';
  static const _kActiveModeId = 'active_mode_id';

  final AppDatabase _appDb;
  final EntryRepository _entries;

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  // ── Custom modes ─────────────────────────────────────────────────────────

  Future<List<ModeDefinition>> customModes() async {
    final db = await _appDb.database;
    final rows = await db.query(AppDatabase.tableModes, orderBy: 'created_at ASC');
    return [
      for (final row in rows)
        customModeFrom(
          id: row['id'] as String,
          name: row['name'] as String,
          emoji: row['emoji'] as String,
        ),
    ];
  }

  /// Built-in modes first, then custom modes oldest-first.
  Future<List<ModeDefinition>> allModes() async {
    return [...kBuiltInModes, ...await customModes()];
  }

  Future<ModeDefinition> createCustom({
    required String name,
    required String emoji,
  }) async {
    final db = await _appDb.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = 'custom_$now';
    await db.insert(
      AppDatabase.tableModes,
      {'id': id, 'name': name, 'emoji': emoji, 'created_at': now},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return customModeFrom(id: id, name: name, emoji: emoji);
  }

  Future<void> updateCustom(
    String id, {
    required String name,
    required String emoji,
  }) async {
    final db = await _appDb.database;
    await db.update(
      AppDatabase.tableModes,
      {'name': name, 'emoji': emoji},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a custom mode along with every day it logged, and drop it from the
  /// enabled list so nothing points at a mode that no longer exists.
  Future<void> deleteCustom(String id) async {
    final db = await _appDb.database;
    await db.delete(AppDatabase.tableModes, where: 'id = ?', whereArgs: [id]);
    await _entries.deleteAllForMode(id);

    final enabled = await enabledModeIds();
    if (enabled.contains(id)) {
      final remaining = enabled.where((e) => e != id).toList();
      await setEnabledModeIds(
          remaining.isEmpty ? [kDefaultMode.id] : remaining);
    }
    if (await activeModeId() == id) {
      await setActiveModeId((await enabledModeIds()).first);
    }
  }

  // ── Selection ────────────────────────────────────────────────────────────

  Future<List<String>> enabledModeIds() async {
    final prefs = await _p;
    final stored = prefs.getStringList(_kEnabledModeIds);
    if (stored == null || stored.isEmpty) return [kDefaultMode.id];
    return stored;
  }

  Future<void> setEnabledModeIds(List<String> ids) async {
    final prefs = await _p;
    await prefs.setStringList(_kEnabledModeIds, ids);
  }

  Future<String> activeModeId() async {
    final prefs = await _p;
    return prefs.getString(_kActiveModeId) ?? kDefaultMode.id;
  }

  Future<void> setActiveModeId(String id) async {
    final prefs = await _p;
    await prefs.setString(_kActiveModeId, id);
  }

  /// The mode the app should open in. Falls back to [kDefaultMode] when the
  /// stored id names a custom mode that has since been deleted.
  Future<ModeDefinition> resolveActiveMode() async {
    final id = await activeModeId();
    final builtIn = builtInModeById(id);
    if (builtIn != null) return builtIn;
    for (final mode in await customModes()) {
      if (mode.id == id) return mode;
    }
    return kDefaultMode;
  }
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `flutter test test/mode_repository_test.dart`
Expected: PASS — 7 tests.

> If the database tests interfere with each other, note that `AppDatabase.instance` is a singleton holding one connection. The tests above share it deliberately; `SharedPreferences.setMockInitialValues({})` in `setUp` resets the preference half between tests. If a test needs a clean database, delete the rows in `setUp` rather than reaching for a second `AppDatabase`.

- [ ] **Step 5: Run the whole suite and analysis**

Run: `flutter test && flutter analyze`
Expected: all pass, `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/data/repositories/mode_repository.dart test/mode_repository_test.dart
git commit -m "feat: add ModeRepository for custom modes and mode selection"
```

---

### Task 6: Replace DrinkLevel with TrackedLevel

**Files:**
- Delete: `lib/core/models/drink_level.dart`
- Modify: `lib/core/models/day_entry.dart`, `lib/data/repositories/entry_repository.dart`, `lib/services/stats_service.dart`, `lib/core/theme/app_colors.dart`
- Modify: `lib/viewmodels/tracker_viewmodel.dart`
- Modify: `lib/ui/widgets/day_entry_sheet.dart`, `lib/ui/statistics/widgets/distribution_pie.dart`, `lib/ui/dashboard/widgets/month_summary_card.dart`, `lib/ui/calendar/calendar_screen.dart`, `lib/ui/calendar/widgets/month_grid.dart`
- Modify: `lib/services/export_import_service.dart`
- Test: `test/stats_service_test.dart` (ported), `test/mode_isolation_test.dart` (new)

**Why this is one task:** Dart will not compile a half-swapped type. `DayEntry.level` changing from `DrinkLevel` to `TrackedLevel` breaks every consumer at once, so the swap and all its call sites land in a single commit. The change is rename-shaped: mechanical, and fully covered by the ported tests.

**Interfaces:**
- Consumes: `TrackedLevel`, `ModeDefinition.levelForValue` (Task 1), `kDontDrinkMode` (Task 2).
- Produces:
  - `DayEntry({required String modeId, required DateTime date, required TrackedLevel level, ...})`, and `DayEntry.fromMap(Map<String, Object?> map, ModeDefinition mode)` — **note the new second parameter**.
  - `TrackerStats({required int currentStreak, required int longestStreak, required int totalCleanDays, required int totalLoggedDays, required Map<TrackedLevel, int> levelCounts})` with `double get cleanDayPercentage`.
  - `MonthlyTotals({required DateTime month, required int cleanDays, required int otherDays})` with `int get loggedDays`.
  - `StatsService.compute(List<DayEntry> entries, ModeDefinition mode, {DateTime? now})` and `monthLevelCounts(Map<String, DayEntry> monthEntries, ModeDefinition mode)` — **both take the mode**, because a zero-filled counts map needs to know the mode's level list.
  - `EntryRepository` read methods take `ModeDefinition mode` instead of `String modeId`: `getForDate(mode, date)`, `getAll(mode)`, `getRange(mode, start, end)`, `getMonth(mode, month)`, `levelCounts(mode)`. Write methods keep ids: `delete(String modeId, DateTime date)`, `deleteAllForMode(String modeId)`.

- [ ] **Step 1: Write the failing isolation test**

Create `test/mode_isolation_test.dart`:

```dart
import 'package:dont_drink/core/models/day_entry.dart';
import 'package:dont_drink/data/repositories/entry_repository.dart';
import 'package:dont_drink/data/static/modes/dont_drink_mode.dart';
import 'package:dont_drink/data/static/modes/dont_smoke_mode.dart';
import 'package:dont_drink/services/stats_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  final repo = EntryRepository();

  setUp(() async {
    await repo.deleteAllForMode('dont_drink');
    await repo.deleteAllForMode('dont_smoke');
  });

  test('the same date can be logged in two modes independently', () async {
    final date = DateTime(2026, 6, 1);

    await repo.upsert(DayEntry(
      modeId: 'dont_drink',
      date: date,
      level: kDontDrinkLevels[0],
    ));
    await repo.upsert(DayEntry(
      modeId: 'dont_smoke',
      date: date,
      level: kDontSmokeLevels[3],
    ));

    final drink = await repo.getForDate(kDontDrinkMode, date);
    final smoke = await repo.getForDate(kDontSmokeMode, date);

    expect(drink!.level.label, 'No Drinks');
    expect(smoke!.level.label, '16+ Cigarettes');
  });

  test('getAll returns only the requested mode\'s entries', () async {
    await repo.upsert(DayEntry(
      modeId: 'dont_drink',
      date: DateTime(2026, 6, 1),
      level: kDontDrinkLevels[0],
    ));
    await repo.upsert(DayEntry(
      modeId: 'dont_smoke',
      date: DateTime(2026, 6, 1),
      level: kDontSmokeLevels[0],
    ));
    await repo.upsert(DayEntry(
      modeId: 'dont_smoke',
      date: DateTime(2026, 6, 2),
      level: kDontSmokeLevels[0],
    ));

    expect((await repo.getAll(kDontDrinkMode)).length, 1);
    expect((await repo.getAll(kDontSmokeMode)).length, 2);
  });

  test('streaks are computed per mode', () async {
    const stats = StatsService();
    final now = DateTime(2026, 6, 3);

    // Don't Drink: three clean days. Don't Smoke: relapsed today.
    for (final day in [1, 2, 3]) {
      await repo.upsert(DayEntry(
        modeId: 'dont_drink',
        date: DateTime(2026, 6, day),
        level: kDontDrinkLevels[0],
      ));
    }
    await repo.upsert(DayEntry(
      modeId: 'dont_smoke',
      date: DateTime(2026, 6, 3),
      level: kDontSmokeLevels[3],
    ));

    final drink = await repo.getAll(kDontDrinkMode);
    final smoke = await repo.getAll(kDontSmokeMode);

    expect(stats.currentStreak(drink, now: now), 3);
    expect(stats.currentStreak(smoke, now: now), 0);
  });

  test('deleting one mode\'s entries leaves the other untouched', () async {
    await repo.upsert(DayEntry(
      modeId: 'dont_drink',
      date: DateTime(2026, 6, 1),
      level: kDontDrinkLevels[0],
    ));
    await repo.upsert(DayEntry(
      modeId: 'dont_smoke',
      date: DateTime(2026, 6, 1),
      level: kDontSmokeLevels[0],
    ));

    await repo.deleteAllForMode('dont_smoke');

    expect((await repo.getAll(kDontDrinkMode)).length, 1);
    expect((await repo.getAll(kDontSmokeMode)), isEmpty);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/mode_isolation_test.dart`
Expected: FAIL — `The argument type 'ModeDefinition' can't be assigned to the parameter type 'String'` (and `kDontDrinkLevels` is not a `DrinkLevel`).

- [ ] **Step 3: Delete the enum and update the model**

```bash
git rm lib/core/models/drink_level.dart
```

In `lib/core/models/day_entry.dart`: replace the `drink_level.dart` import with

```dart
import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/core/models/tracked_level.dart';
```

change `final DrinkLevel level;` to `final TrackedLevel level;`, change `copyWith`'s `DrinkLevel? level` to `TrackedLevel? level`, and rewrite `fromMap` to take the mode:

```dart
  /// Rebuild an entry from a database row. [mode] is required because a level
  /// integer only has meaning within its own mode.
  factory DayEntry.fromMap(Map<String, Object?> map, ModeDefinition mode) {
    return DayEntry(
      modeId: map['mode_id'] as String? ?? mode.id,
      date: DateOnly.parseKey(map['date_key'] as String),
      level: mode.levelForValue(map['level'] as int),
      note: map['note'] as String?,
      updatedAt: map['updated_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    );
  }
```

- [ ] **Step 4: Update `EntryRepository` to take modes on reads**

In `lib/data/repositories/entry_repository.dart`, swap the `drink_level.dart` import for `mode_definition.dart` and `tracked_level.dart`, then change each read method to accept `ModeDefinition mode` and pass it to `fromMap`:

```dart
  Future<DayEntry?> getForDate(ModeDefinition mode, DateTime date) async {
    final db = await _appDb.database;
    final rows = await db.query(
      AppDatabase.tableEntries,
      where: 'mode_id = ? AND date_key = ?',
      whereArgs: [mode.id, DateOnly.keyFor(date)],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DayEntry.fromMap(rows.first, mode);
  }

  Future<List<DayEntry>> getAll(ModeDefinition mode) async {
    final db = await _appDb.database;
    final rows = await db.query(
      AppDatabase.tableEntries,
      where: 'mode_id = ?',
      whereArgs: [mode.id],
      orderBy: 'date_key ASC',
    );
    return [for (final row in rows) DayEntry.fromMap(row, mode)];
  }

  Future<Map<String, DayEntry>> getRange(
      ModeDefinition mode, DateTime start, DateTime end) async {
    final db = await _appDb.database;
    final rows = await db.query(
      AppDatabase.tableEntries,
      where: 'mode_id = ? AND date_key BETWEEN ? AND ?',
      whereArgs: [mode.id, DateOnly.keyFor(start), DateOnly.keyFor(end)],
    );
    return {
      for (final row in rows)
        row['date_key'] as String: DayEntry.fromMap(row, mode),
    };
  }

  Future<Map<String, DayEntry>> getMonth(ModeDefinition mode, DateTime month) {
    return getRange(
        mode, DateOnly.firstOfMonth(month), DateOnly.lastOfMonth(month));
  }

  Future<Map<TrackedLevel, int>> levelCounts(ModeDefinition mode) async {
    final entries = await getAll(mode);
    final counts = {for (final level in mode.levels) level: 0};
    for (final entry in entries) {
      counts[entry.level] = (counts[entry.level] ?? 0) + 1;
    }
    return counts;
  }
```

`delete(String modeId, DateTime date)`, `deleteAllForMode(String modeId)` and `upsert(DayEntry entry)` keep their current signatures.

- [ ] **Step 5: Update `StatsService`**

In `lib/services/stats_service.dart`: swap the import, rename the alcohol-specific members, and thread the mode through the two methods that build a zero-filled counts map.

```dart
import 'package:dont_drink/core/models/day_entry.dart';
import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/core/models/tracked_level.dart';
import 'package:dont_drink/core/utils/date_utils.dart';

/// Aggregate statistics computed from a set of [DayEntry] rows, all belonging
/// to a single mode.
class TrackerStats {
  const TrackerStats({
    required this.currentStreak,
    required this.longestStreak,
    required this.totalCleanDays,
    required this.totalLoggedDays,
    required this.levelCounts,
  });

  /// Consecutive clean days ending today (or yesterday if today is unlogged —
  /// see [StatsService.currentStreak]).
  final int currentStreak;

  /// Best clean run ever recorded.
  final int longestStreak;

  final int totalCleanDays;
  final int totalLoggedDays;

  /// Count of logged days per level.
  final Map<TrackedLevel, int> levelCounts;

  /// Clean percentage of logged days (0–100).
  double get cleanDayPercentage {
    if (totalLoggedDays == 0) return 0;
    return (totalCleanDays / totalLoggedDays) * 100;
  }

  static const empty = TrackerStats(
    currentStreak: 0,
    longestStreak: 0,
    totalCleanDays: 0,
    totalLoggedDays: 0,
    levelCounts: {},
  );
}
```

In `currentStreak` and `longestStreak`, replace every `entry.level.isAlcoholFree` / `todayEntry.level.isAlcoholFree` with `.level.isClean`. The streak algorithms are otherwise unchanged.

```dart
  /// Compute the full statistics bundle for [mode].
  TrackerStats compute(
    List<DayEntry> entries,
    ModeDefinition mode, {
    DateTime? now,
  }) {
    final counts = {for (final level in mode.levels) level: 0};
    int clean = 0;
    for (final entry in entries) {
      counts[entry.level] = (counts[entry.level] ?? 0) + 1;
      if (entry.level.isClean) clean++;
    }
    return TrackerStats(
      currentStreak: currentStreak(entries, now: now),
      longestStreak: longestStreak(entries),
      totalCleanDays: clean,
      totalLoggedDays: entries.length,
      levelCounts: counts,
    );
  }

  /// Count entries by level for a single month of [mode].
  Map<TrackedLevel, int> monthLevelCounts(
    Map<String, DayEntry> monthEntries,
    ModeDefinition mode,
  ) {
    final counts = {for (final level in mode.levels) level: 0};
    for (final entry in monthEntries.values) {
      counts[entry.level] = (counts[entry.level] ?? 0) + 1;
    }
    return counts;
  }
```

Rename `MonthlyTotals`' fields and the aggregation that builds them:

```dart
/// Clean vs. non-clean counts for one calendar month.
class MonthlyTotals {
  const MonthlyTotals({
    required this.month,
    required this.cleanDays,
    required this.otherDays,
  });

  final DateTime month;
  final int cleanDays;
  final int otherDays;

  int get loggedDays => cleanDays + otherDays;
}

extension MonthlyAggregation on StatsService {
  /// Clean / non-clean totals for the [count] most recent months ending with
  /// the month containing [now]. Always returns [count] entries (zero-filled)
  /// so charts have a stable x-axis.
  List<MonthlyTotals> recentMonths(
    List<DayEntry> entries, {
    int count = 6,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final buckets = <String, MonthlyTotals>{};

    for (final entry in entries) {
      final key = '${entry.date.year}-${entry.date.month}';
      final existing = buckets[key];
      final clean = entry.level.isClean ? 1 : 0;
      buckets[key] = MonthlyTotals(
        month: DateTime(entry.date.year, entry.date.month),
        cleanDays: (existing?.cleanDays ?? 0) + clean,
        otherDays: (existing?.otherDays ?? 0) + (1 - clean),
      );
    }

    final result = <MonthlyTotals>[];
    for (int i = count - 1; i >= 0; i--) {
      final m = DateTime(reference.year, reference.month - i);
      final key = '${m.year}-${m.month}';
      result.add(
        buckets[key] ?? MonthlyTotals(month: m, cleanDays: 0, otherDays: 0),
      );
    }
    return result;
  }
}
```

- [ ] **Step 6: Drop the status colors from `app_colors.dart`**

The five status constants mirrored `DrinkLevel`; each mode's levels now carry their own colors. Delete them and keep only `AppColors.green` (still used by `streak_hero.dart`'s gradient):

```dart
import 'package:flutter/material.dart';

/// Centralized palette for app chrome. Per-day status colors live on each
/// mode's [TrackedLevel]s, not here.
class AppColors {
  AppColors._();

  /// Used by the streak gradient and "good news" accents.
  static const Color green = Color(0xFF4CAF50);

  // Brand accent — a calm teal/green that reads as "healthy".
  static const Color brand = Color(0xFF2E9E83);
  static const Color brandDark = Color(0xFF1F7A65);

  // Light theme surfaces.
  static const Color lightBackground = Color(0xFFF5F7F8);
  static const Color lightSurface = Color(0xFFFFFFFF);

  // Dark theme surfaces.
  static const Color darkBackground = Color(0xFF101417);
  static const Color darkSurface = Color(0xFF1A2025);
}
```

Run `grep -rn "AppColors.yellow\|AppColors.orange\|AppColors.red\|AppColors.black" lib` and fix any hits before moving on. If `app_theme.dart` references them, replace with the literal color it needs.

- [ ] **Step 7: Update `TrackerViewModel` minimally**

The full mode-scoping lands in Task 7; here just make it compile against the new types. In `lib/viewmodels/tracker_viewmodel.dart`:

- Replace the `drink_level.dart` import with `mode_definition.dart` and `tracked_level.dart`.
- Add a private field and constructor parameter: `required ModeDefinition mode` → `_mode`, with `ModeDefinition get mode => _mode;`.
- `load()`: `final all = await _repo.getAll(_mode);`
- `_recompute()`: `_statsCache = _stats.compute(_allEntries, _mode);`
- `monthCounts`: `_stats.monthLevelCounts(entriesForMonth(month), _mode)` returning `Map<TrackedLevel, int>`.
- `logDay(DateTime date, TrackedLevel level, {String? note})`, constructing `DayEntry(modeId: _mode.id, ...)`.
- `clearDay`: `await _repo.delete(_mode.id, date);`
- `achievements` / `nextAchievement`: leave calling `AchievementService` as-is for now (Task 8 parameterizes it).

In `lib/main.dart`, construct with the default mode so the app still runs:

```dart
import 'package:dont_drink/data/static/modes/mode_registry.dart';
...
final trackerViewModel =
    TrackerViewModel(repository: EntryRepository(), mode: kDefaultMode);
```

- [ ] **Step 8: Update the five level-iterating UI files**

Each currently iterates `DrinkLevel.values`; each now takes the levels it should render. **Do not** reach for the active mode via `context.read` inside these leaf widgets — pass the list in, so they stay testable.

**`lib/ui/widgets/day_entry_sheet.dart`:** replace the `drink_level.dart` import with `tracked_level.dart`; in `build`, read the mode from the view model that is already watched:

```dart
    final vm = context.watch<TrackerViewModel>();
    final mode = vm.mode;
```

then `for (final level in mode.levels)`, and change `_LevelOption.level` and `_save`'s parameter to `TrackedLevel`. The doc comment becomes "Presents the active mode's levels; tapping one saves instantly…".

**`lib/ui/statistics/widgets/distribution_pie.dart`:** add a `levels` parameter so the chart knows the full scale and its order:

```dart
class DistributionPie extends StatelessWidget {
  const DistributionPie({
    super.key,
    required this.counts,
    required this.levels,
  });

  final Map<TrackedLevel, int> counts;
  final List<TrackedLevel> levels;
  ...
    final present = levels.where((l) => (counts[l] ?? 0) > 0).toList();
```

**`lib/ui/dashboard/widgets/month_summary_card.dart`:** same shape —

```dart
  const MonthSummaryCard({super.key, required this.counts, required this.levels});

  final Map<TrackedLevel, int> counts;
  final List<TrackedLevel> levels;
```

replacing both `for (final level in DrinkLevel.values)` loops with `for (final level in levels)`, and `_LevelRow.level` with `TrackedLevel`.

**`lib/ui/calendar/calendar_screen.dart`:** `_Legend` and `_MonthStats` both gain a `levels` list, and `_MonthStats` gains the mode's `cleanDayLabel` and clean level:

```dart
class _Legend extends StatelessWidget {
  const _Legend({required this.levels});
  final List<TrackedLevel> levels;
  ...
        for (final level in levels)
```

```dart
class _MonthStats extends StatelessWidget {
  const _MonthStats({
    required this.counts,
    required this.mode,
  });

  final Map<TrackedLevel, int> counts;
  final ModeDefinition mode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = counts.values.fold(0, (a, b) => a + b);
    final clean = counts[mode.cleanLevel] ?? 0;
    final pct = total == 0 ? 0 : (clean / total * 100).round();
    ...
              _Stat(value: '$total', label: 'Logged'),
              _Stat(value: '$clean', label: mode.cleanDayLabel),
              _Stat(value: '$pct%', label: 'Clean rate'),
    ...
          for (final level in mode.levels)
```

and in `CalendarScreen.build`, pass them: `_Legend(levels: vm.mode.levels)` and `_MonthStats(counts: counts, mode: vm.mode)`.

**`lib/ui/calendar/widgets/month_grid.dart`:** only the doc comment mentions `DrinkLevel` — change it to "tinted by that day's [TrackedLevel]". `_DayCell` reads `entry?.level.color` and `entry?.level.onColor`, which both still exist. No functional change.

**`lib/ui/statistics/statistics_screen.dart`:** pass the new parameters through at both call sites — `MonthSummaryCard(counts: ..., levels: vm.mode.levels)` and `DistributionPie(counts: ..., levels: vm.mode.levels)` — and rename the stats fields it reads (`stats.alcoholFreePercentage` → `stats.cleanDayPercentage`, `t.alcoholFreeDays` → `t.cleanDays`). Copy is retitled in Task 8; here just make it compile.

**`lib/ui/dashboard/widgets/quick_stats_row.dart`** and **`lib/ui/statistics/widgets/monthly_bar_chart.dart`:** rename the same stats fields (`totalAlcoholFreeDays` → `totalCleanDays`, `alcoholFreeDays` → `cleanDays`). Copy is retitled in Task 8.

- [ ] **Step 9: Update `export_import_service.dart` to compile**

`DayEntry.fromMap` now needs a mode. Import `mode_registry.dart` and pass `kDefaultMode` for now — Task 11 replaces this with real per-mode resolution:

```dart
final entry = DayEntry.fromMap(Map<String, Object?>.from(raw), kDefaultMode);
```

- [ ] **Step 10: Port `test/stats_service_test.dart`**

Replace the imports and the `_entry` helper; the assertions change only where fields were renamed.

```dart
import 'package:dont_drink/core/models/day_entry.dart';
import 'package:dont_drink/core/models/tracked_level.dart';
import 'package:dont_drink/data/static/modes/dont_drink_mode.dart';
import 'package:dont_drink/services/stats_service.dart';
import 'package:flutter_test/flutter_test.dart';

// `const` is not possible here: indexing a const list is not a constant
// expression in Dart.
final _none = kDontDrinkLevels[0];
final _light = kDontDrinkLevels[1];
final _heavy = kDontDrinkLevels[3];

DayEntry _entry(DateTime date, TrackedLevel level) =>
    DayEntry(modeId: 'dont_drink', date: date, level: level);
```

Then across the file replace `DrinkLevel.none` → `_none`, `DrinkLevel.light` → `_light`, `DrinkLevel.heavy` → `_heavy`; in the `compute` group call `service.compute(entries, kDontDrinkMode, now: now)` and assert `stats.totalCleanDays` / `stats.cleanDayPercentage`; in the `recentMonths` group assert `months.last.cleanDays` and `months.last.otherDays`.

- [ ] **Step 11: Run every test and analysis**

Run: `flutter test`
Expected: PASS — `stats_service_test.dart` (7), `tracked_level_test.dart` (9), `mode_registry_test.dart` (10), `mode_repository_test.dart` (7), `migration_test.dart` (4), `mode_isolation_test.dart` (4).

Run: `flutter analyze`
Expected: `No issues found!` — in particular, no remaining reference to `DrinkLevel` anywhere:

```bash
grep -rn "DrinkLevel\|isAlcoholFree\|alcoholFreePercentage\|totalAlcoholFreeDays\|alcoholFreeDays" lib test
# expect: no output
```

- [ ] **Step 12: Commit**

```bash
git add -A
git commit -m "refactor: replace DrinkLevel enum with per-mode TrackedLevel"
```

---

### Task 7: ModeViewModel, mode switching and startup wiring

**Files:**
- Create: `lib/viewmodels/mode_viewmodel.dart`
- Modify: `lib/viewmodels/tracker_viewmodel.dart`
- Modify: `lib/main.dart`
- Test: `test/mode_viewmodel_test.dart`

**Interfaces:**
- Consumes: `ModeRepository` (Task 5), `EntryRepository`, `StatsService`.
- Produces:
  - `ModeRuleError` — thrown when an activation rule is violated; carries a `message` suitable for a snackbar.
  - `ModeViewModel({required ModeRepository repository, required EntryRepository entries, required Future<void> Function(ModeDefinition) onActiveModeChanged, StatsService stats = const StatsService()})` with `activeMode`, `enabledModes`, `allAvailableModes`, `streakFor(String modeId)`, `load()`, `setActive(String id)`, `setEnabled(String id, bool enabled)`, `createCustom(String name, String emoji)`, `updateCustom(String id, String name, String emoji)`, `deleteCustom(String id)`, `refreshStreaks()`.
  - `TrackerViewModel.switchMode(ModeDefinition mode)` and a settable `VoidCallback? onDataChanged`.

- [ ] **Step 1: Write the failing test**

Create `test/mode_viewmodel_test.dart`:

```dart
import 'package:dont_drink/core/models/day_entry.dart';
import 'package:dont_drink/data/repositories/entry_repository.dart';
import 'package:dont_drink/data/repositories/mode_repository.dart';
import 'package:dont_drink/data/static/modes/dont_drink_mode.dart';
import 'package:dont_drink/viewmodels/mode_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late EntryRepository entries;
  late List<String> switched;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    entries = EntryRepository();
    switched = [];
    for (final id in ['dont_drink', 'dont_smoke', 'no_contact']) {
      await entries.deleteAllForMode(id);
    }
  });

  Future<ModeViewModel> buildVm() async {
    final vm = ModeViewModel(
      repository: ModeRepository(entries: entries),
      entries: entries,
      onActiveModeChanged: (mode) async => switched.add(mode.id),
    );
    await vm.load();
    return vm;
  }

  test('starts on Don\'t Drink with only Don\'t Drink enabled', () async {
    final vm = await buildVm();
    expect(vm.activeMode.id, 'dont_drink');
    expect(vm.enabledModes.map((m) => m.id), ['dont_drink']);
    expect(vm.allAvailableModes.length, 3);
  });

  test('enabling a mode adds it to the switcher', () async {
    final vm = await buildVm();
    await vm.setEnabled('dont_smoke', true);
    expect(vm.enabledModes.map((m) => m.id), ['dont_drink', 'dont_smoke']);
  });

  test('setActive notifies the tracker', () async {
    final vm = await buildVm();
    await vm.setEnabled('dont_smoke', true);
    await vm.setActive('dont_smoke');
    expect(vm.activeMode.id, 'dont_smoke');
    expect(switched, ['dont_smoke']);
  });

  test('cannot deactivate the active mode', () async {
    final vm = await buildVm();
    await vm.setEnabled('dont_smoke', true);
    await vm.setActive('dont_smoke');
    await expectLater(
      vm.setEnabled('dont_smoke', false),
      throwsA(isA<ModeRuleError>()),
    );
    expect(vm.enabledModes.length, 2);
  });

  test('cannot disable the last enabled mode', () async {
    final vm = await buildVm();
    await expectLater(
      vm.setEnabled('dont_drink', false),
      throwsA(isA<ModeRuleError>()),
    );
    expect(vm.enabledModes.map((m) => m.id), ['dont_drink']);
  });

  test('streakFor reports a non-active mode\'s streak', () async {
    await entries.upsert(DayEntry(
      modeId: 'dont_smoke',
      date: DateTime.now().subtract(const Duration(days: 1)),
      level: kDontDrinkLevels[0],
    ));
    await entries.upsert(DayEntry(
      modeId: 'dont_smoke',
      date: DateTime.now(),
      level: kDontDrinkLevels[0],
    ));

    final vm = await buildVm();
    await vm.setEnabled('dont_smoke', true);

    expect(vm.activeMode.id, 'dont_drink');
    expect(vm.streakFor('dont_smoke'), 2);
    expect(vm.streakFor('dont_drink'), 0);
  });

  test('creating a custom mode enables and lists it', () async {
    final vm = await buildVm();
    final mode = await vm.createCustom('No Sugar', '🍭');
    expect(vm.allAvailableModes.map((m) => m.id), contains(mode.id));
    expect(vm.enabledModes.map((m) => m.id), contains(mode.id));
  });

  test('deleting the active custom mode falls back to an enabled one', () async {
    final vm = await buildVm();
    final mode = await vm.createCustom('Temp', '🎯');
    await vm.setActive(mode.id);
    switched.clear();

    await vm.deleteCustom(mode.id);

    expect(vm.activeMode.id, 'dont_drink');
    expect(vm.allAvailableModes.map((m) => m.id), isNot(contains(mode.id)));
    expect(switched, ['dont_drink']);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/mode_viewmodel_test.dart`
Expected: FAIL — `Target of URI doesn't exist: '.../mode_viewmodel.dart'`.

- [ ] **Step 3: Write `mode_viewmodel.dart`**

```dart
import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/data/repositories/entry_repository.dart';
import 'package:dont_drink/data/repositories/mode_repository.dart';
import 'package:dont_drink/services/stats_service.dart';
import 'package:flutter/foundation.dart';

/// Raised when an activation rule is violated. [message] is written for the
/// user and can be shown directly in a snackbar.
class ModeRuleError implements Exception {
  const ModeRuleError(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Owns which tracking modes exist, which are enabled, and which one the app
/// is currently showing.
///
/// It also caches a current streak per enabled mode, because the switcher and
/// the settings list show streaks for modes that [TrackerViewModel] — which is
/// scoped to exactly one mode — knows nothing about.
class ModeViewModel extends ChangeNotifier {
  ModeViewModel({
    required ModeRepository repository,
    required EntryRepository entries,
    required this.onActiveModeChanged,
    StatsService stats = const StatsService(),
  })  : _repo = repository,
        _entries = entries,
        _stats = stats;

  final ModeRepository _repo;
  final EntryRepository _entries;
  final StatsService _stats;

  /// Called whenever the active mode changes, so the tracker can reload.
  final Future<void> Function(ModeDefinition mode) onActiveModeChanged;

  List<ModeDefinition> _all = const [];
  List<ModeDefinition> get allAvailableModes => List.unmodifiable(_all);

  List<String> _enabledIds = const [];
  List<ModeDefinition> get enabledModes =>
      [for (final id in _enabledIds) _byId(id)].nonNulls.toList();

  ModeDefinition? _active;
  ModeDefinition get activeMode => _active ?? _all.first;

  final Map<String, int> _streaks = {};

  /// Current streak for [modeId], or 0 if it has not been computed.
  int streakFor(String modeId) => _streaks[modeId] ?? 0;

  ModeDefinition? _byId(String id) {
    for (final mode in _all) {
      if (mode.id == id) return mode;
    }
    return null;
  }

  Future<void> load() async {
    _all = await _repo.allModes();
    _enabledIds = await _repo.enabledModeIds();
    _active = await _repo.resolveActiveMode();
    await refreshStreaks();
    notifyListeners();
  }

  /// Recompute the cached streak for every enabled mode. Cheap: at most one
  /// row per day per mode.
  Future<void> refreshStreaks() async {
    for (final mode in enabledModes) {
      final rows = await _entries.getAll(mode);
      _streaks[mode.id] = _stats.currentStreak(rows);
    }
    notifyListeners();
  }

  Future<void> setActive(String id) async {
    final mode = _byId(id);
    if (mode == null || mode.id == _active?.id) return;
    _active = mode;
    notifyListeners();
    await _repo.setActiveModeId(id);
    await onActiveModeChanged(mode);
  }

  /// Enable or disable a mode.
  ///
  /// Disabling is refused for the active mode and for the last enabled mode —
  /// the switcher must always have somewhere to land.
  Future<void> setEnabled(String id, bool enabled) async {
    if (!enabled) {
      if (id == activeMode.id) {
        throw const ModeRuleError(
            'Switch to another mode before turning this one off.');
      }
      if (_enabledIds.length <= 1) {
        throw const ModeRuleError('At least one mode has to stay on.');
      }
      _enabledIds = _enabledIds.where((e) => e != id).toList();
    } else if (!_enabledIds.contains(id)) {
      _enabledIds = [..._enabledIds, id];
    } else {
      return;
    }
    notifyListeners();
    await _repo.setEnabledModeIds(_enabledIds);
    await refreshStreaks();
  }

  Future<ModeDefinition> createCustom(String name, String emoji) async {
    final mode = await _repo.createCustom(name: name, emoji: emoji);
    _all = await _repo.allModes();
    _enabledIds = [..._enabledIds, mode.id];
    await _repo.setEnabledModeIds(_enabledIds);
    await refreshStreaks();
    notifyListeners();
    return mode;
  }

  Future<void> updateCustom(String id, String name, String emoji) async {
    await _repo.updateCustom(id, name: name, emoji: emoji);
    _all = await _repo.allModes();
    if (_active?.id == id) {
      _active = _byId(id);
      await onActiveModeChanged(activeMode);
    }
    notifyListeners();
  }

  /// Delete a custom mode and everything it logged. If it was active, fall
  /// back to the first remaining enabled mode.
  Future<void> deleteCustom(String id) async {
    final wasActive = _active?.id == id;
    await _repo.deleteCustom(id);
    _all = await _repo.allModes();
    _enabledIds = await _repo.enabledModeIds();
    if (wasActive) {
      _active = await _repo.resolveActiveMode();
      await onActiveModeChanged(activeMode);
    }
    _streaks.remove(id);
    await refreshStreaks();
    notifyListeners();
  }

  /// How many days [modeId] has logged — shown in the delete confirmation.
  Future<int> loggedDayCount(String modeId) async {
    final mode = _byId(modeId);
    if (mode == null) return 0;
    return (await _entries.getAll(mode)).length;
  }
}
```

- [ ] **Step 4: Add `switchMode` and `onDataChanged` to `TrackerViewModel`**

In `lib/viewmodels/tracker_viewmodel.dart`, make `_mode` mutable and add:

```dart
  ModeDefinition _mode;
  ModeDefinition get mode => _mode;

  /// Called after any change to this mode's entries, so [ModeViewModel] can
  /// refresh its cached per-mode streaks.
  VoidCallback? onDataChanged;

  /// Point this view model at a different mode and reload its history.
  Future<void> switchMode(ModeDefinition mode) async {
    if (mode.id == _mode.id) {
      _mode = mode; // a rename of the same mode
      notifyListeners();
      return;
    }
    _mode = mode;
    _visibleMonth = DateOnly.firstOfMonth(DateTime.now());
    _pendingUnlocks = const [];
    await load();
  }
```

Call `onDataChanged?.call()` at the end of `logDay` and `clearDay`, after `notifyListeners()`.

- [ ] **Step 5: Wire startup in `main.dart`**

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Notifications init is best-effort; the app works fully without them.
  await NotificationService.instance.init();

  final entryRepository = EntryRepository();
  final modeRepository = ModeRepository(entries: entryRepository);

  // The tracker is scoped to one mode, so the active mode has to be resolved
  // before it can be built.
  final activeMode = await modeRepository.resolveActiveMode();
  final trackerViewModel =
      TrackerViewModel(repository: entryRepository, mode: activeMode);
  final settingsViewModel = SettingsViewModel(repository: SettingsRepository());

  await Future.wait([
    trackerViewModel.load(),
    settingsViewModel.load(),
  ]);

  final modeViewModel = ModeViewModel(
    repository: modeRepository,
    entries: entryRepository,
    onActiveModeChanged: trackerViewModel.switchMode,
  );
  await modeViewModel.load();
  trackerViewModel.onDataChanged = modeViewModel.refreshStreaks;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: trackerViewModel),
        ChangeNotifierProvider.value(value: settingsViewModel),
        ChangeNotifierProvider.value(value: modeViewModel),
      ],
      child: const DontDrinkApp(),
    ),
  );
}
```

Add the imports for `ModeRepository` and `ModeViewModel`.

- [ ] **Step 6: Run the test to verify it passes**

Run: `flutter test test/mode_viewmodel_test.dart`
Expected: PASS — 8 tests.

- [ ] **Step 7: Run everything**

Run: `flutter test && flutter analyze`
Expected: all pass, `No issues found!`

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat: add ModeViewModel, mode switching and startup wiring"
```

---

### Task 8: Drive content and copy from the active mode

**Files:**
- Modify: `lib/services/achievement_service.dart`
- Modify: `lib/viewmodels/tracker_viewmodel.dart`
- Modify: `lib/ui/facts/facts_screen.dart`, `lib/ui/recovery/recovery_screen.dart`, `lib/ui/widgets/recovery_section.dart`, `lib/ui/motivation/motivation_screen.dart`, `lib/ui/more/more_screen.dart`
- Modify: `lib/ui/statistics/statistics_screen.dart`, `lib/ui/dashboard/widgets/quick_stats_row.dart`, `lib/ui/dashboard/widgets/streak_hero.dart`, `lib/ui/statistics/widgets/monthly_bar_chart.dart`

**Interfaces:**
- Consumes: `ModeDefinition.content`, `ModeDefinition.cleanDayLabel`, `TrackerViewModel.mode`.
- Produces: `AchievementService.evaluate({required List<Achievement> achievements, required int longestStreak})`, `newlyUnlocked({required List<Achievement> achievements, required int previousLongest, required int newLongest})`, `nextLocked(List<Achievement> achievements, int longestStreak)`.

- [ ] **Step 1: Parameterize `AchievementService`**

Rewrite `lib/services/achievement_service.dart` so it stops importing `achievements_data.dart` and takes the list instead:

```dart
import 'package:dont_drink/core/models/achievement.dart';

/// A view of an achievement plus whether the user has unlocked it.
class AchievementStatus {
  const AchievementStatus({required this.achievement, required this.unlocked});

  final Achievement achievement;
  final bool unlocked;
}

/// Derives achievement unlock state from streak data.
///
/// An achievement is considered permanently earned once the user's *longest*
/// streak in that mode has ever reached its threshold — so a relapse doesn't
/// erase a badge. The achievement list comes from the active mode's content
/// pack, so badges never cross between modes.
class AchievementService {
  const AchievementService();

  List<AchievementStatus> evaluate({
    required List<Achievement> achievements,
    required int longestStreak,
  }) {
    return achievements
        .map((a) => AchievementStatus(
              achievement: a,
              unlocked: longestStreak >= a.dayThreshold,
            ))
        .toList();
  }

  List<Achievement> newlyUnlocked({
    required List<Achievement> achievements,
    required int previousLongest,
    required int newLongest,
  }) {
    return achievements
        .where((a) =>
            a.dayThreshold > previousLongest && a.dayThreshold <= newLongest)
        .toList();
  }

  Achievement? nextLocked(List<Achievement> achievements, int longestStreak) {
    for (final a in achievements) {
      if (longestStreak < a.dayThreshold) return a;
    }
    return null;
  }
}
```

Update the three call sites in `lib/viewmodels/tracker_viewmodel.dart` to pass `_mode.content.achievements`.

- [ ] **Step 2: Drive Facts from the pack**

In `lib/ui/facts/facts_screen.dart`, drop the `facts_data.dart` import of the alcohol lists and read the active mode instead. The fact-of-the-day picker uses `pack.facts`:

```dart
    final pack = context.watch<TrackerViewModel>().mode.content;
    ...
    // fact of the day
    pack.facts[dayOfYear % pack.facts.length]
    ...
            SectionHeader(pack.harmsTitle),
            for (final fact in pack.harms) ...,
            SectionHeader(pack.benefitsTitle),
            for (final fact in pack.benefits) ...,
```

Guard the empty case — a custom mode has no facts — by returning a centered message when `!pack.hasFacts`:

```dart
    if (!pack.hasFacts) {
      return const Scaffold(
        body: Center(child: Text('This mode has no facts yet.')),
      );
    }
```

Note `_factOfDay` is held in state; move its initialization into `build` (or into `didChangeDependencies`) so switching modes picks a fact from the new pack.

- [ ] **Step 3: Drive Recovery from the pack**

In `lib/ui/recovery/recovery_screen.dart` and `lib/ui/widgets/recovery_section.dart`, replace `kRecoveryByTier` / `kRecoveryTimeline` with the active mode's pack:

```dart
    final vm = context.watch<TrackerViewModel>();
    final pack = vm.mode.content;
    final byTier = pack.recoveryByTier;
    final totalMilestones = pack.recoveryMilestones.length;
    final reached = pack.recoveryMilestones
        .where((m) => streakHours >= m.afterHours)
        .length;
```

Replace the alcohol-specific empty-state line in `recovery_screen.dart:45` with a mode-neutral one:

```dart
: 'Start a streak to begin your recovery journey.',
```

In `recovery_section.dart`, return `const SizedBox.shrink()` when `!pack.hasRecovery` so the Achievements screen simply omits the section for a custom mode.

- [ ] **Step 4: Drive Motivation from the pack**

In `lib/ui/motivation/motivation_screen.dart`, replace all four `kMotivations` references with `context.watch<TrackerViewModel>().mode.content.motivations`, read once at the top of `build` into a local `motivations`. Every mode ships motivations, so no empty guard is needed — but clamp the page index if the new list is shorter after a mode switch.

- [ ] **Step 5: Hide empty rows on the More screen**

In `lib/ui/more/more_screen.dart`, build the item list from the active mode instead of a const list:

```dart
    final pack = context.watch<TrackerViewModel>().mode.content;
    final items = <_MoreItem>[
      if (pack.hasRecovery)
        _MoreItem(
          title: 'Recovery Timeline',
          subtitle: pack.recoverySubtitle,
          builder: (_) => const RecoveryScreen(),
        ),
      if (pack.hasFacts)
        _MoreItem(
          title: 'Facts',
          subtitle: pack.factsSubtitle,
          builder: (_) => const FactsScreen(),
        ),
      _MoreItem(
        title: 'Motivation',
        subtitle: 'A boost when you need it',
        builder: (_) => const MotivationScreen(),
      ),
      _MoreItem(
        title: 'Settings',
        subtitle: 'Modes, theme, reminders & privacy',
        builder: (_) => const SettingsScreen(),
      ),
    ];
```

- [ ] **Step 6: Retitle the stats and streak copy**

**`lib/ui/statistics/statistics_screen.dart`:**
- `SectionHeader('Alcohol-Free Days per Month')` → `SectionHeader('${mode.cleanDayLabel} Days per Month')`
- `SectionHeader('Drinking Distribution')` → `SectionHeader('Day Distribution')`
- `_row(context, 'Alcohol-free rate', ...)` → `_row(context, '${mode.cleanDayLabel} rate', ...)`
- the best-month row's `'(${bestMonth.cleanDays} free)'` → `'(${bestMonth.cleanDays} clean)'`

where `mode` is `context.watch<TrackerViewModel>().mode`.

**`lib/ui/dashboard/widgets/quick_stats_row.dart`:** add a `cleanDayLabel` parameter and use it for the label currently reading `'Alcohol-free'`. Pass `vm.mode.cleanDayLabel` from the statistics screen.

**`lib/ui/dashboard/widgets/streak_hero.dart`:** add a `cleanDayLabel` parameter and replace the hardcoded `'alcohol-free'` with `cleanDayLabel.toLowerCase()`. Pass `vm.mode.cleanDayLabel` from `dashboard_screen.dart`.

**`lib/ui/statistics/widgets/monthly_bar_chart.dart`:** update the doc comment to "Bar chart of clean days for each of the recent months." (the field renames already landed in Task 6).

- [ ] **Step 7: Verify no alcohol copy survives outside Don't Drink's content**

```bash
grep -rni "alcohol" lib --include='*.dart' | grep -v "data/static/facts_data.dart" \
  | grep -v "data/static/achievements_data.dart" \
  | grep -v "data/static/recovery_timeline_data.dart" \
  | grep -v "data/static/motivation_data.dart" \
  | grep -v "data/static/modes/dont_drink_mode.dart"
# expect: no output
```

- [ ] **Step 8: Run everything**

Run: `flutter test && flutter analyze`
Expected: all pass, `No issues found!`

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "feat: drive achievements, facts, recovery and copy from the active mode"
```

---

### Task 9: Settings ▸ Modes

**Files:**
- Create: `lib/ui/settings/widgets/modes_section.dart`
- Create: `lib/ui/modes/custom_mode_editor.dart`
- Modify: `lib/ui/settings/settings_screen.dart`

**Interfaces:**
- Consumes: `ModeViewModel` (Task 7), `ModeRuleError`.
- Produces: `ModesSection` (a `StatelessWidget` taking no arguments) and `CustomModeEditor.show(BuildContext context, {ModeDefinition? existing})` returning `Future<void>`.

- [ ] **Step 1: Write `custom_mode_editor.dart`**

```dart
import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/viewmodels/mode_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Create or rename a custom mode. Custom modes have a fixed level scale, so
/// only the name and emoji are editable.
class CustomModeEditor extends StatefulWidget {
  const CustomModeEditor({super.key, this.existing});

  /// The mode being renamed, or null when creating a new one.
  final ModeDefinition? existing;

  static Future<void> show(BuildContext context, {ModeDefinition? existing}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: CustomModeEditor(existing: existing),
      ),
    );
  }

  @override
  State<CustomModeEditor> createState() => _CustomModeEditorState();
}

class _CustomModeEditorState extends State<CustomModeEditor> {
  static const _emojiChoices = [
    '🎯', '🎲', '🍭', '📱', '💸', '🛌', '🍔', '☕', '🎮', '🧘',
  ];

  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late String _emoji = widget.existing?.emoji ?? _emojiChoices.first;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _canSave => _name.text.trim().isNotEmpty && !_saving;

  Future<void> _save() async {
    final vm = context.read<ModeViewModel>();
    final name = _name.text.trim();
    setState(() => _saving = true);
    try {
      if (widget.existing == null) {
        await vm.createCustom(name, _emoji);
      } else {
        await vm.updateCustom(widget.existing!.id, name, _emoji);
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNew = widget.existing == null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isNew ? 'New mode' : 'Rename mode',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Custom modes track clean days, slips and relapses.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _name,
              autofocus: isNew,
              textCapitalization: TextCapitalization.words,
              maxLength: 24,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. No Sugar',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _canSave ? _save() : null,
            ),
            const SizedBox(height: 8),
            Text('Icon', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final emoji in _emojiChoices)
                  ChoiceChip(
                    label: Text(emoji, style: const TextStyle(fontSize: 18)),
                    selected: _emoji == emoji,
                    onSelected: (_) => setState(() => _emoji = emoji),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _canSave ? _save : null,
                child: Text(isNew ? 'Create mode' : 'Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Write `modes_section.dart`**

```dart
import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/ui/modes/custom_mode_editor.dart';
import 'package:dont_drink/ui/widgets/app_card.dart';
import 'package:dont_drink/viewmodels/mode_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The Settings ▸ Modes card: turn modes on and off, switch the active one,
/// and manage custom modes.
class ModesSection extends StatelessWidget {
  const ModesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ModeViewModel>();

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          for (final mode in vm.allAvailableModes)
            _ModeTile(mode: mode, vm: vm),
          const Divider(height: 1, indent: 56),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Create custom mode'),
            subtitle: const Text('Track any habit with clean days and slips'),
            onTap: () => CustomModeEditor.show(context),
          ),
        ],
      ),
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({required this.mode, required this.vm});

  final ModeDefinition mode;
  final ModeViewModel vm;

  bool get _enabled => vm.enabledModes.any((m) => m.id == mode.id);
  bool get _isActive => vm.activeMode.id == mode.id;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final streak = vm.streakFor(mode.id);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: Text(mode.emoji, style: const TextStyle(fontSize: 22)),
      title: Row(
        children: [
          Flexible(child: Text(mode.name)),
          if (_isActive) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Active',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: _enabled
          ? Text('$streak day streak')
          : const Text('Off — your data is kept'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!mode.isBuiltIn)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Rename',
              onPressed: () => CustomModeEditor.show(context, existing: mode),
            ),
          if (!mode.isBuiltIn)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: () => _confirmDelete(context),
            ),
          Switch(
            value: _enabled,
            onChanged: (on) => _toggle(context, on),
          ),
        ],
      ),
      onTap: _enabled && !_isActive ? () => vm.setActive(mode.id) : null,
    );
  }

  Future<void> _toggle(BuildContext context, bool on) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await vm.setEnabled(mode.id, on);
    } on ModeRuleError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final count = await vm.loggedDayCount(mode.id);
    if (!context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete ${mode.name}?'),
        content: Text(
          count == 0
              ? 'This mode has no logged days. It will be removed permanently.'
              : 'This will permanently delete this mode and its '
                  '$count logged ${count == 1 ? "day" : "days"}. '
                  'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await vm.deleteCustom(mode.id);
    }
  }
}
```

- [ ] **Step 3: Add the section to the Settings screen**

In `lib/ui/settings/settings_screen.dart`, insert above the existing `Appearance` header:

```dart
            const SectionHeader('Modes'),
            const ModesSection(),
            const SizedBox(height: 24),
            const SectionHeader('Appearance'),
```

and import `modes_section.dart`.

- [ ] **Step 4: Verify by running the app**

Run: `flutter run`

Check by hand:
1. Settings shows three modes; only Don't Drink is on and marked Active.
2. Turning Don't Smoke on adds a `0 day streak` subtitle; tapping its row makes it Active and the dashboard's data changes.
3. Turning off the active mode shows the snackbar "Switch to another mode before turning this one off." and leaves the switch on.
4. With only one mode on, turning it off shows "At least one mode has to stay on."
5. Creating a custom mode adds it to the list, already enabled.
6. Deleting a custom mode with logged days names the count in the dialog.

- [ ] **Step 5: Run tests and analysis**

Run: `flutter test && flutter analyze`
Expected: all pass, `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: add Settings mode list and custom mode editor"
```

---

### Task 10: Dashboard mode switcher

**Files:**
- Create: `lib/ui/widgets/mode_switcher.dart`
- Modify: `lib/ui/dashboard/dashboard_screen.dart`
- Modify: `lib/ui/shell/home_shell.dart`

**Interfaces:**
- Consumes: `ModeViewModel`.
- Produces: `ModeSwitcher` — a `StatelessWidget` intended as a `SliverAppBar.title`.

- [ ] **Step 1: Write `mode_switcher.dart`**

```dart
import 'package:dont_drink/viewmodels/mode_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// The dashboard's app-bar title: the active mode's name, tappable to switch
/// between enabled modes.
///
/// When only one mode is enabled it renders as a plain title — there is
/// nothing to switch to, so the affordance would be a lie.
class ModeSwitcher extends StatelessWidget {
  const ModeSwitcher({super.key, required this.onManageModes});

  /// Opens Settings, where modes are turned on and off.
  final VoidCallback onManageModes;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ModeViewModel>();
    final theme = Theme.of(context);
    final active = vm.activeMode;

    if (vm.enabledModes.length <= 1) {
      return Text(active.name);
    }

    return PopupMenuButton<String>(
      tooltip: 'Switch mode',
      position: PopupMenuPosition.under,
      onSelected: (value) {
        if (value == _manageValue) {
          onManageModes();
        } else {
          vm.setActive(value);
        }
      },
      itemBuilder: (context) => [
        for (final mode in vm.enabledModes)
          PopupMenuItem<String>(
            value: mode.id,
            child: Row(
              children: [
                Text(mode.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 12),
                Expanded(child: Text(mode.name)),
                const SizedBox(width: 12),
                Text(
                  '${vm.streakFor(mode.id)} d',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.check,
                  size: 18,
                  color: mode.id == active.id
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                ),
              ],
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: _manageValue,
          child: Row(
            children: [
              Icon(Icons.tune, size: 18),
              SizedBox(width: 12),
              Text('Manage modes…'),
            ],
          ),
        ),
      ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(active.name),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down),
        ],
      ),
    );
  }

  static const _manageValue = '__manage__';
}
```

- [ ] **Step 2: Let the shell be told to show Settings**

The switcher's "Manage modes…" row has to reach the Settings tab, which `HomeShell` owns. Expose the shell's tab index through a static handle rather than threading a callback through three widgets.

In `lib/ui/shell/home_shell.dart`, add above the class:

```dart
/// Lets a descendant jump to one of the shell's tabs — used by the mode
/// switcher's "Manage modes…" row.
class HomeShellController {
  HomeShellController._();
  static final instance = HomeShellController._();

  void Function(int index)? _select;

  /// Index 3 is the Settings tab.
  static const int settingsTab = 3;

  void selectTab(int index) => _select?.call(index);
}
```

and in `_HomeShellState`:

```dart
  @override
  void initState() {
    super.initState();
    HomeShellController.instance._select =
        (i) => setState(() => _index = i);
  }

  @override
  void dispose() {
    HomeShellController.instance._select = null;
    super.dispose();
  }
```

- [ ] **Step 3: Use the switcher as the dashboard title**

In `lib/ui/dashboard/dashboard_screen.dart`, replace the const app bar:

```dart
            SliverAppBar(
              floating: true,
              title: ModeSwitcher(
                onManageModes: () => HomeShellController.instance
                    .selectTab(HomeShellController.settingsTab),
              ),
            ),
```

and import `mode_switcher.dart` and `home_shell.dart`.

Also pass the mode's clean-day label into the hero (from Task 8):

```dart
                  StreakHero(
                    currentStreak: vm.stats.currentStreak,
                    longestStreak: vm.stats.longestStreak,
                    cleanDayLabel: vm.mode.cleanDayLabel,
                  ),
```

- [ ] **Step 4: Verify by running the app**

Run: `flutter run`

Check by hand:
1. With one mode enabled, the dashboard title is plain text with no dropdown arrow.
2. Enable a second mode in Settings → the title grows a `▾` and opens a menu.
3. The menu lists each enabled mode with emoji, name and streak, with a check on the active one.
4. Selecting another mode changes the dashboard streak, calendar colors and level picker to that mode's scale — a No Contact day sheet shows four options, a custom mode shows three.
5. "Manage modes…" jumps to the Settings tab.

- [ ] **Step 5: Run tests and analysis**

Run: `flutter test && flutter analyze`
Expected: all pass, `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add -A
git commit -m "feat: add dashboard mode switcher"
```

---

### Task 11: Multi-mode export and import

**Files:**
- Modify: `lib/services/export_import_service.dart`
- Modify: `lib/ui/settings/settings_screen.dart` (`_DataSection` call sites)
- Test: `test/export_import_test.dart`

**Interfaces:**
- Consumes: `ModeRepository`, `EntryRepository`, `ModeViewModel`.
- Produces:
  - `ExportImportService.buildPayload({required List<ModeDefinition> modes, required Map<String, List<DayEntry>> entriesByMode})` → `Map<String, Object?>` (pure, so it can be tested without a share sheet).
  - `ExportImportService.applyPayload(Map<String, dynamic> payload, {required EntryRepository entries, required ModeRepository modes})` → `Future<ImportResult>` (pure of file pickers, same reason).
  - `export(...)` and `import(...)` keep driving the OS dialogs and delegate to those two.

- [ ] **Step 1: Write the failing test**

Create `test/export_import_test.dart`:

```dart
import 'package:dont_drink/core/models/day_entry.dart';
import 'package:dont_drink/data/repositories/entry_repository.dart';
import 'package:dont_drink/data/repositories/mode_repository.dart';
import 'package:dont_drink/data/static/modes/dont_drink_mode.dart';
import 'package:dont_drink/data/static/modes/dont_smoke_mode.dart';
import 'package:dont_drink/services/export_import_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  const service = ExportImportService();
  late EntryRepository entries;
  late ModeRepository modes;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    entries = EntryRepository();
    modes = ModeRepository(entries: entries);
    for (final id in ['dont_drink', 'dont_smoke']) {
      await entries.deleteAllForMode(id);
    }
    for (final m in await modes.customModes()) {
      await modes.deleteCustom(m.id);
    }
  });

  test('buildPayload is version 2 and carries mode ids', () {
    final payload = service.buildPayload(
      modes: const [],
      entriesByMode: {
        'dont_drink': [
          DayEntry(
            modeId: 'dont_drink',
            date: DateTime(2026, 6, 1),
            level: kDontDrinkLevels[0],
          ),
        ],
        'dont_smoke': [
          DayEntry(
            modeId: 'dont_smoke',
            date: DateTime(2026, 6, 1),
            level: kDontSmokeLevels[2],
          ),
        ],
      },
    );

    expect(payload['version'], 2);
    expect(payload['app'], 'dont_drink');
    final rows = payload['entries'] as List;
    expect(rows.length, 2);
    expect(rows.map((r) => (r as Map)['mode_id']).toSet(),
        {'dont_drink', 'dont_smoke'});
  });

  test('buildPayload includes custom mode definitions', () async {
    final custom = await modes.createCustom(name: 'No Sugar', emoji: '🍭');
    final payload = service.buildPayload(
      modes: [custom],
      entriesByMode: const {},
    );
    final defs = payload['custom_modes'] as List;
    expect(defs.length, 1);
    expect((defs.first as Map)['name'], 'No Sugar');
    expect((defs.first as Map)['id'], custom.id);
  });

  test('a version 1 payload imports into Don\'t Drink', () async {
    final result = await service.applyPayload(
      {
        'version': 1,
        'app': 'dont_drink',
        'entries': [
          {
            'date_key': '2026-06-01',
            'level': 0,
            'note': 'legacy',
            'updated_at': 1750000000000,
          },
        ],
      },
      entries: entries,
      modes: modes,
    );

    expect(result, isA<ImportSuccess>());
    final stored = await entries.getAll(kDontDrinkMode);
    expect(stored.length, 1);
    expect(stored.single.modeId, 'dont_drink');
    expect(stored.single.note, 'legacy');
  });

  test('a version 2 payload restores several modes', () async {
    final result = await service.applyPayload(
      {
        'version': 2,
        'app': 'dont_drink',
        'custom_modes': const [],
        'entries': [
          {
            'mode_id': 'dont_drink',
            'date_key': '2026-06-01',
            'level': 0,
            'note': null,
            'updated_at': 1750000000000,
          },
          {
            'mode_id': 'dont_smoke',
            'date_key': '2026-06-01',
            'level': 2,
            'note': null,
            'updated_at': 1750000000000,
          },
        ],
      },
      entries: entries,
      modes: modes,
    );

    expect(result, isA<ImportSuccess>());
    expect((await entries.getAll(kDontDrinkMode)).length, 1);
    final smoke = await entries.getAll(kDontSmokeMode);
    expect(smoke.single.level.label, '6–15 Cigarettes');
  });

  test('importing recreates a custom mode and its entries', () async {
    final result = await service.applyPayload(
      {
        'version': 2,
        'app': 'dont_drink',
        'custom_modes': [
          {'id': 'custom_9', 'name': 'No Sugar', 'emoji': '🍭'},
        ],
        'entries': [
          {
            'mode_id': 'custom_9',
            'date_key': '2026-06-01',
            'level': 1,
            'note': null,
            'updated_at': 1750000000000,
          },
        ],
      },
      entries: entries,
      modes: modes,
    );

    expect(result, isA<ImportSuccess>());
    final restored = (await modes.customModes()).single;
    expect(restored.id, 'custom_9');
    expect(restored.name, 'No Sugar');
    expect((await entries.getAll(restored)).single.level.shortLabel, 'Slip');
  });

  test('a payload from another app is rejected', () async {
    final result = await service.applyPayload(
      {'version': 2, 'app': 'something_else', 'entries': const []},
      entries: entries,
      modes: modes,
    );
    expect(result, isA<ImportError>());
  });

  test('entries for an unknown mode are skipped, not fatal', () async {
    final result = await service.applyPayload(
      {
        'version': 2,
        'app': 'dont_drink',
        'custom_modes': const [],
        'entries': [
          {
            'mode_id': 'custom_gone',
            'date_key': '2026-06-01',
            'level': 0,
            'note': null,
            'updated_at': 1750000000000,
          },
          {
            'mode_id': 'dont_drink',
            'date_key': '2026-06-02',
            'level': 0,
            'note': null,
            'updated_at': 1750000000000,
          },
        ],
      },
      entries: entries,
      modes: modes,
    );

    expect((result as ImportSuccess).count, 1);
    expect((await entries.getAll(kDontDrinkMode)).length, 1);
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `flutter test test/export_import_test.dart`
Expected: FAIL — `The method 'buildPayload' isn't defined for the type 'ExportImportService'`.

- [ ] **Step 3: Split the pure logic out of `export_import_service.dart`**

Add these two methods to `ExportImportService` (keeping `ImportResult` and friends unchanged):

```dart
  /// Build the backup payload. Pure — no file or share-sheet involvement — so
  /// the format can be tested directly.
  Map<String, Object?> buildPayload({
    required List<ModeDefinition> modes,
    required Map<String, List<DayEntry>> entriesByMode,
  }) {
    final rows = [
      for (final list in entriesByMode.values)
        for (final entry in list) entry.toMap(),
    ];
    return {
      'version': 2,
      'app': 'dont_drink',
      'exported_at': DateOnly.keyFor(DateTime.now()),
      'entry_count': rows.length,
      'custom_modes': [
        for (final mode in modes)
          if (!mode.isBuiltIn)
            {'id': mode.id, 'name': mode.name, 'emoji': mode.emoji},
      ],
      'entries': rows,
    };
  }

  /// Apply a decoded backup payload. Pure of file pickers for the same reason.
  ///
  /// Accepts both version 1 (single-mode, no `mode_id`) and version 2. Entries
  /// naming a mode that cannot be resolved are skipped rather than failing the
  /// whole import.
  Future<ImportResult> applyPayload(
    Map<String, dynamic> payload, {
    required EntryRepository entries,
    required ModeRepository modes,
  }) async {
    if (payload['app'] != 'dont_drink') {
      return const ImportError(
          "This file doesn't look like a Don't Drink backup.");
    }

    final rawEntries = payload['entries'];
    if (rawEntries is! List) {
      return const ImportError('Backup file is missing the entries list.');
    }

    // Recreate any custom modes the backup carried, so their entries resolve.
    final rawModes = payload['custom_modes'];
    if (rawModes is List) {
      final existing = {for (final m in await modes.customModes()) m.id};
      for (final raw in rawModes) {
        if (raw is! Map) continue;
        final id = raw['id'] as String?;
        final name = raw['name'] as String?;
        if (id == null || name == null || existing.contains(id)) continue;
        await modes.restoreCustom(
          id: id,
          name: name,
          emoji: raw['emoji'] as String? ?? '🎯',
        );
      }
    }

    // Index every known mode by id so a level integer can be resolved.
    final byId = {for (final mode in await modes.allModes()) mode.id: mode};

    int count = 0;
    try {
      for (final raw in rawEntries) {
        if (raw is! Map) continue;
        final map = Map<String, Object?>.from(raw);
        final modeId = map['mode_id'] as String? ?? kDefaultMode.id;
        final mode = byId[modeId];
        if (mode == null) continue; // unknown mode — skip, don't fail
        await entries.upsert(DayEntry.fromMap(map, mode));
        count++;
      }
    } catch (e) {
      return ImportError('Import failed after $count entries: $e');
    }

    return ImportSuccess(count);
  }
```

Add the imports it needs: `mode_definition.dart`, `mode_repository.dart`, `mode_registry.dart`.

- [ ] **Step 4: Add `restoreCustom` to `ModeRepository`**

`createCustom` mints a new id; restoring a backup must keep the id the entries reference. Add to `lib/data/repositories/mode_repository.dart`:

```dart
  /// Recreate a custom mode with its original id — used when importing a
  /// backup, where entries already reference that id.
  Future<ModeDefinition> restoreCustom({
    required String id,
    required String name,
    required String emoji,
  }) async {
    final db = await _appDb.database;
    await db.insert(
      AppDatabase.tableModes,
      {
        'id': id,
        'name': name,
        'emoji': emoji,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return customModeFrom(id: id, name: name, emoji: emoji);
  }
```

- [ ] **Step 5: Rewire `export()` and `import()` to the new helpers**

`export` now takes everything it needs rather than a single entry list:

```dart
  Future<void> export({
    required List<ModeDefinition> modes,
    required Map<String, List<DayEntry>> entriesByMode,
  }) async {
    final payload = buildPayload(modes: modes, entriesByMode: entriesByMode);
    final json = const JsonEncoder.withIndent('  ').convert(payload);
    ...unchanged file write and Share.shareXFiles...
  }
```

`import` keeps the picker and the read, then hands the decoded map to `applyPayload`:

```dart
  Future<ImportResult> import({
    required EntryRepository entries,
    required ModeRepository modes,
  }) async {
    ...unchanged picker + read + jsonDecode into `payload`...
    return applyPayload(payload, entries: entries, modes: modes);
  }
```

- [ ] **Step 6: Update the Settings data section**

In `lib/ui/settings/settings_screen.dart`'s `_DataSectionState`:

```dart
  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      final modeVm = context.read<ModeViewModel>();
      final repo = EntryRepository();
      final modes = modeVm.allAvailableModes;
      final byMode = <String, List<DayEntry>>{
        for (final mode in modes) mode.id: await repo.getAll(mode),
      };
      await _service.export(modes: modes, entriesByMode: byMode);
    } catch (e) {
      if (mounted) _showSnack('Export failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
```

and in `_import()`:

```dart
      final repo = EntryRepository();
      final result = await _service.import(
        entries: repo,
        modes: ModeRepository(entries: repo),
      );
      ...
        case ImportSuccess(:final count):
          await context.read<TrackerViewModel>().load();
          if (context.mounted) await context.read<ModeViewModel>().load();
```

Update the import confirmation dialog text to say it spans modes:

```
'Importing a backup will merge its entries with your current data, across all '
'modes. Days already logged will be overwritten with the values from the file. '
'Days not present in the file are left unchanged.\n\nContinue?'
```

- [ ] **Step 7: Run the test to verify it passes**

Run: `flutter test test/export_import_test.dart`
Expected: PASS — 7 tests.

- [ ] **Step 8: Run everything**

Run: `flutter test && flutter analyze`
Expected: all pass, `No issues found!`

- [ ] **Step 9: Commit**

```bash
git add -A
git commit -m "feat: export and import all modes with v1 backup compatibility"
```

---

### Task 12: Notification copy, README and final verification

**Files:**
- Modify: `lib/services/notification_service.dart`
- Modify: `README.md`

- [ ] **Step 1: Keep one reminder, mode-neutral**

Three active modes must not mean three nightly notifications. The reminder stays global; only the title needs to stop naming alcohol implicitly. In `lib/services/notification_service.dart`, leave `scheduleDailyReminder`'s schedule and id alone and keep the title as the app name:

```dart
      title: "Don't Drink",
      body: 'How did today go? Tap to log your day.',
```

Both strings are already mode-neutral and the app keeps its name, so **no code change is required here** — add a comment recording the decision so a future reader does not "fix" it into per-mode reminders:

```dart
    // One reminder for the whole app, not one per active mode: several active
    // modes should not mean several nightly pings.
```

- [ ] **Step 2: Document modes in the README**

Add a `### Tracking Modes` section under Features, before `### Daily Tracker`:

```markdown
### Tracking Modes
The app can track more than alcohol. Turn modes on in **Settings ▸ Modes**, then
switch between them from the dashboard title.

| Mode | Levels | Content |
|---|---|---|
| Don't Drink | None / 1–2 / 3–5 / 6+ / Blackout | Full facts, recovery timeline, awards |
| Don't Smoke | None / 1–5 / 6–15 / 16+ / Chain | Full facts, recovery timeline, awards |
| No Contact | No contact / Thought about it / Checked profile / Reached out | Full facts, recovery timeline, awards |
| Custom | Clean / Slip / Relapse | Generic awards and motivations |

Each mode keeps its own history, streak, calendar and achievements — a relapse
in one mode never touches another. Turning a mode off keeps its data; deleting
a custom mode deletes its days.
```

Update the `Daily Tracker` section's opening to say "Log exactly one status per day per mode", and the Architecture tree to include the new directories:

```
├── core/
│   ├── models/         # ModeDefinition, TrackedLevel, ContentPack, DayEntry, Achievement
...
├── data/
│   ├── static/modes/   # Built-in mode definitions + content packs
│   ├── repositories/   # EntryRepository, ModeRepository, SettingsRepository
├── viewmodels/         # TrackerViewModel, ModeViewModel, SettingsViewModel
└── ui/
    ├── modes/          # Custom mode editor
```

Update the tests line under "Run tests" to describe the real suite:

```markdown
Covers streak calculation, longest-streak detection, monthly aggregation, stats
computation, mode definitions and invariants, the v1→v2 database migration,
per-mode entry isolation, mode activation rules, and export/import across modes.
```

- [ ] **Step 3: Full verification**

Run each and confirm the stated output before claiming the feature is done:

```bash
flutter analyze          # expect: No issues found!
flutter test             # expect: All tests passed
flutter build apk --debug
```

- [ ] **Step 4: Manual smoke test on the migration path**

This is the one thing tests cannot fully prove. Install the **previous** release over a device with real data, then install this build over it:

```bash
git stash list  # ensure a clean tree first
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

Confirm: existing days still show their colors, the streak is unchanged, the longest streak is unchanged, and the dashboard opens on Don't Drink.

- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "docs: document tracking modes in the README"
```

---

## Notes for the implementer

**Running one test file at a time is the fast loop.** `flutter test test/<file>.dart` takes seconds; the full suite plus analyze takes a minute. Run the focused file while iterating, and the full pair before every commit.

**The database is a singleton.** `AppDatabase.instance` holds one connection for the whole process, so test files that touch it share state. Every database test above clears the rows it cares about in `setUp` rather than trying to get a fresh database — follow that pattern for anything new.

**`kDontDrinkLevels[0]` is not a constant expression.** Use `final` for test fixtures that index into a const list.

**If `flutter pub get` rewrites `android/local.properties`,** set `sdk.dir` back to `/home/ben/Android/Sdk`. The `/opt` SDK has no NDK and no accepted licenses, and the build will fail confusingly.
