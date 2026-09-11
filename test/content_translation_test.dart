import 'package:dont_drink/data/static/modes/custom_mode.dart';
import 'package:dont_drink/data/static/modes/mode_registry.dart';
import 'package:dont_drink/l10n/content/content_strings.dart';
import 'package:dont_drink/l10n/content/mode_localizer.dart';
import 'package:flutter_test/flutter_test.dart';

/// Content translations are plain maps, so nothing but this test stops a
/// forgotten string from silently falling back to English, or a typo'd key
/// from sitting in the map doing nothing.
void main() {
  final modes = [
    ...kBuiltInModes,
    customModeFrom(id: 'custom_sample', name: 'Sample', emoji: '🎯'),
  ];

  final expected = <String, String>{
    for (final mode in modes) ...contentKeysFor(mode),
  };

  for (final strings in [ContentStrings.german, ContentStrings.italian]) {
    group(strings.languageCode, () {
      test('translates every content string', () {
        final missing =
            expected.keys.where((k) => strings[k] == null).toList()..sort();
        expect(missing, isEmpty,
            reason: '${strings.languageCode} is missing these content keys');
      });

      test('has no keys the content does not use', () {
        final unknown =
            strings.keys.where((k) => !expected.containsKey(k)).toList()
              ..sort();
        expect(unknown, isEmpty,
            reason: '${strings.languageCode} defines keys nothing reads — '
                'a typo, or content that was removed');
      });

      test('leaves no English text behind', () {
        final untouched = <String>[];
        for (final entry in expected.entries) {
          // Mode names are brand names and stay as they are; "Motivation" and
          // the like would be flagged wrongly, so compare only longer copy.
          if (entry.key.endsWith('.name') && entry.key.startsWith('mode.')) {
            continue;
          }
          if (entry.value.length > 25 && strings[entry.key] == entry.value) {
            untouched.add(entry.key);
          }
        }
        expect(untouched, isEmpty,
            reason: 'these ${strings.languageCode} strings are still the '
                'English original');
      });
    });
  }

  test('localized() rewrites a mode through the map', () {
    final drink = kBuiltInModes.first.localized(ContentStrings.german);
    expect(drink.id, 'dont_drink', reason: 'ids must never be translated');
    expect(drink.cleanDayLabel, 'Alkoholfrei');
    expect(drink.levels.first.label, 'Keine Drinks');
    expect(drink.levels.first.value, 0, reason: 'persisted values stay put');
    expect(drink.levels.first.isClean, isTrue);
    expect(
      drink.content.achievements.first.title,
      'Die Leber atmet auf',
    );
    expect(drink.content.achievements.first.id, 'dont_drink.day_1',
        reason: 'achievement ids are keys, not copy');
    expect(drink.content.recoveryMilestones.first.name, 'Der Ausgangspunkt');
    expect(drink.content.facts.first.isHarm, isTrue);
  });

  test('a custom mode keeps its own name but gets translated content', () {
    final custom = customModeFrom(id: 'custom_1', name: 'Kein Zucker', emoji: '🍭')
        .localized(ContentStrings.italian);
    expect(custom.name, 'Kein Zucker',
        reason: 'the user typed this — never translate it');
    expect(custom.cleanDayLabel, 'Pulito');
    expect(custom.levels[1].label, 'Scivolone');
    expect(custom.content.achievements.first.title, 'Primo giorno fatto');
    expect(custom.content.achievements.first.id, 'custom_1.day_1');
  });

  test('English is the identity transform', () {
    final mode = kBuiltInModes.first;
    expect(identical(mode.localized(ContentStrings.english), mode), isTrue);
  });
}
