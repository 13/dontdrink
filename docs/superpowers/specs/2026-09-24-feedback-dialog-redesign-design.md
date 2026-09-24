# Day feedback dialog redesign

The cheer / comfort dialog shown after logging a day without earning a badge
(`lib/ui/widgets/day_feedback_dialog.dart`).

## Goals
- Look modern and calm, clearly quieter than `AchievementUnlockDialog`.
- Never lose a button off the edge, in any language or text size.
- Make the comfort reassurance concrete.

## Design
- **Card:** gradient in the tint color (16% alpha at the top, fading to
  transparent by the middle) over the normal dialog surface. Radius 28,
  content centered.
- **Tint:** `AppColors.brand` for cheer, new `AppColors.warm` (#E8A87C) for
  comfort. A slip should read as warm, not as a warning.
- **Hero emoji:** 🌱 / 🫶 in a 76dp tinted circle with a soft glow. Hidden
  from screen readers.
- **Comfort chip:** a "STILL YOURS" label above a pill showing
  "🏅 4 badges · 🏆 18-day best". A part that is 0 is left out, and with both
  at 0 the chip is not shown. Screen readers get one label for the whole chip.
  This replaces the `comfortKept` sentence.
- **Buttons:** stacked and full width. The close button is a `FilledButton`;
  under comfort, the boost `TextButton` goes below it.
- **Motion:** about 280ms of fade, 16px lift and a scale from 0.96 to 1 with
  `easeOutCubic`. No animation when `disableAnimations` is set.

## Data
`DayFeedbackDialog` takes a new `bestStreak`, fed from
`vm.stats.longestStreak` through `_LogOutcome`.

## Strings
`comfortKeptLabel`, `comfortKeptBadges(count)` and `comfortKeptBest(count)`
in en/de/it. `comfortKept` is removed.

## Tests
Widget tests in `test/day_entry_sheet_widget_test.dart`:
- the German dialog at 360px wide keeps both buttons inside the dialog
- the chip shows both numbers
- a part that is 0 is hidden
- there is no chip when both are 0
- the cheer has one button and no chip
