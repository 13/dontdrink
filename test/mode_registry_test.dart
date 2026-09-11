import 'package:dont_drink/data/static/modes/custom_mode.dart';
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
}
