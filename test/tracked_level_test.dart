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
