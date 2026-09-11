import 'package:flutter/widgets.dart';

/// The languages the app ships translations for.
///
/// English first: it is the template locale and the fallback whenever the
/// system language is one the app does not speak.
const List<Locale> kSupportedLocales = [
  Locale('en'),
  Locale('de'),
  Locale('it'),
];

/// Native name of each language, shown in the Settings picker. Deliberately
/// not translated — a language is listed under its own name so someone who
/// cannot read the current UI language can still find theirs.
const Map<String, String> kLanguageNames = {
  'en': 'English',
  'de': 'Deutsch',
  'it': 'Italiano',
};
