/// A single educational fact card.
class Fact {
  const Fact({required this.text, required this.isHarm});

  final String text;

  /// True = "alcohol harm", false = "benefit of not drinking".
  final bool isHarm;
}

const List<Fact> kAlcoholHarms = [
  Fact(text: 'Alcohol disrupts sleep quality.', isHarm: true),
  Fact(text: 'Alcohol increases cancer risk.', isHarm: true),
  Fact(text: 'Alcohol can increase anxiety.', isHarm: true),
  Fact(text: 'Alcohol slows muscle recovery.', isHarm: true),
  Fact(text: 'Alcohol impairs decision making.', isHarm: true),
  Fact(text: 'Alcohol contributes to dehydration.', isHarm: true),
  Fact(text: 'Alcohol increases blood pressure.', isHarm: true),
  Fact(text: 'Alcohol weakens the immune system.', isHarm: true),
  Fact(text: 'Alcohol adds empty calories.', isHarm: true),
];

const List<Fact> kBenefits = [
  Fact(text: 'Better sleep.', isHarm: false),
  Fact(text: 'Better skin.', isHarm: false),
  Fact(text: 'More energy.', isHarm: false),
  Fact(text: 'Better concentration.', isHarm: false),
  Fact(text: 'Improved fitness recovery.', isHarm: false),
  Fact(text: 'Weight management.', isHarm: false),
  Fact(text: 'Better mood stability.', isHarm: false),
  Fact(text: 'More money saved.', isHarm: false),
];

/// All facts combined, used by the rotating "fact of the day" picker.
const List<Fact> kAllFacts = [...kAlcoholHarms, ...kBenefits];
