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
