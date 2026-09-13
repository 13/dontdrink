import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The .arb files have no equivalent of the content-pack parity test, and
/// nothing else would catch a gap: gen-l10n writes untranslated keys to
/// l10n-untranslated.txt (gitignored), and at runtime a missing German string
/// falls back to English silently. A user would just see one English sentence
/// in the middle of their language and have no idea it was a bug.
void main() {
  // Called while the test file is being built, i.e. outside any test body,
  // so it cannot use expect().
  Map<String, dynamic> load(String locale) {
    final file = File('lib/l10n/app_$locale.arb');
    if (!file.existsSync()) {
      throw StateError('${file.path} is missing');
    }
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  /// Message keys, without the @-prefixed metadata entries.
  Set<String> messageKeys(Map<String, dynamic> arb) =>
      arb.keys.where((k) => !k.startsWith('@')).toSet();

  /// The placeholders a message is declared to take, from the template's
  /// @-metadata. That declaration is what gen-l10n turns into method
  /// parameters, so it is the contract every translation has to honour.
  Set<String> declaredPlaceholders(Map<String, dynamic> arb, String key) {
    final meta = arb['@$key'];
    if (meta is! Map) return const {};
    final declared = meta['placeholders'];
    if (declared is! Map) return const {};
    return declared.keys.cast<String>().toSet();
  }

  /// Whether [message] actually uses [placeholder], in either the bare
  /// `{name}` form or as the argument of an ICU plural or select.
  bool usesPlaceholder(String message, String placeholder) =>
      message.contains('{$placeholder}') ||
      RegExp('\\{$placeholder,').hasMatch(message);

  final template = load('en');
  final templateKeys = messageKeys(template);

  test('the template has messages at all', () {
    expect(templateKeys, isNotEmpty);
  });

  for (final locale in ['de', 'it']) {
    group(locale, () {
      final arb = load(locale);
      final keys = messageKeys(arb);

      test('translates every message', () {
        final missing = (templateKeys.difference(keys)).toList()..sort();
        expect(missing, isEmpty,
            reason: '$locale is missing these messages, which would silently '
                'appear in English');
      });

      test('has no message the template does not', () {
        final extra = (keys.difference(templateKeys)).toList()..sort();
        expect(extra, isEmpty,
            reason: '$locale defines messages nothing reads — a typo, or a '
                'string removed from the template');
      });

      test('honours every placeholder the template declares', () {
        final dropped = <String>[];
        for (final key in templateKeys.intersection(keys)) {
          for (final placeholder in declaredPlaceholders(template, key)) {
            if (!usesPlaceholder(arb[key] as String, placeholder)) {
              dropped.add('$key needs {$placeholder}');
            }
          }
        }
        expect(dropped, isEmpty,
            reason: 'a placeholder dropped in translation means the value — a '
                'count, a date, an error — never appears for that language');
      });

      test('leaves no message as the untouched English original', () {
        final untouched = <String>[];
        for (final key in templateKeys.intersection(keys)) {
          final english = template[key] as String;
          final translated = arb[key] as String;
          // Short strings and brand names legitimately match across
          // languages ("Motivation", "Don't Drink", "×{count}").
          if (english.length > 25 && english == translated) {
            untouched.add(key);
          }
        }
        expect(untouched, isEmpty,
            reason: 'these $locale messages are still the English sentence');
      });
    });
  }
}
