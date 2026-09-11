import 'package:dont_drink/core/models/mode_definition.dart';
import 'package:dont_drink/data/static/modes/dont_drink_mode.dart';
import 'package:dont_drink/data/static/modes/dont_smoke_mode.dart';
import 'package:dont_drink/data/static/modes/no_contact_mode.dart';

/// Every mode that ships with the app. Custom modes live in the database and
/// are appended by [ModeRepository] at runtime.
const List<ModeDefinition> kBuiltInModes = [
  kDontDrinkMode,
  kDontSmokeMode,
  kNoContactMode,
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
