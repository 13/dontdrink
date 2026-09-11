import 'package:dont_drink/l10n/content/content_de.dart';
import 'package:dont_drink/l10n/content/content_it.dart';
import 'package:flutter/widgets.dart';

/// Translations for the *content* a mode carries — achievement titles, facts,
/// the recovery timeline, motivations, level names.
///
/// These cannot go through gen-l10n: the content is data, walked by index and
/// id at runtime, and generated `AppLocalizations` only exposes one getter per
/// message. So each language is a flat `key -> text` map here, and
/// `ModeLocalization.localized` rewrites a [ModeDefinition] through it.
///
/// English is the empty map on purpose: the English text is the data itself,
/// in `lib/data/static/`, and a missing key anywhere falls back to it. The
/// parity test in `test/content_translation_test.dart` is what stops that
/// fallback from quietly hiding a forgotten translation.
class ContentStrings {
  const ContentStrings(this.languageCode, this._values);

  final String languageCode;
  final Map<String, String> _values;

  /// Translated text for [key], or null to keep the English original.
  String? operator [](String key) => _values[key];

  /// Every key this language defines — used by the parity test.
  Iterable<String> get keys => _values.keys;

  static const english = ContentStrings('en', {});
  static const german = ContentStrings('de', kContentDe);
  static const italian = ContentStrings('it', kContentIt);

  static ContentStrings of(Locale locale) => switch (locale.languageCode) {
        'de' => german,
        'it' => italian,
        _ => english,
      };
}
