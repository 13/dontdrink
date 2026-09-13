/// What to show after someone logs a day.
enum DayFeedback {
  /// A clean day that earned no badge — a small, quiet acknowledgement.
  cheer,

  /// A non-clean day. Same calm tone whatever the level: ranking how bad a
  /// day was feeds the shame that drives the next one, and the entry is data,
  /// not a verdict.
  comfort,
}

/// Decides which quiet message a log deserves, or none at all.
///
/// Kept a pure function so the rules are testable without a widget tree, and
/// so the one place that answers "does this deserve a reaction?" is not buried
/// in a button handler.
DayFeedback? feedbackFor({
  required bool isToday,
  required bool isClean,
  required bool earnedBadge,
  required bool changed,
}) {
  // The unlock dialog is the celebration; a cheer behind it would be two
  // dialogs for one tap.
  if (earnedBadge) return null;

  // Filling in last Tuesday is bookkeeping. Cheering it would ring hollow,
  // and comforting a day already lived through reopens it for no reason.
  if (!isToday) return null;

  // Re-tapping the level that is already saved changed nothing, so it should
  // not produce a reaction.
  if (!changed) return null;

  return isClean ? DayFeedback.cheer : DayFeedback.comfort;
}

/// Index of the message variant to show on [date], within a list of [count].
///
/// Deterministic per calendar day: re-logging the same day never reshuffles
/// the wording, and the next day reads differently. Same approach as the
/// "fact of the day" picker.
int feedbackVariant(DateTime date, int count) {
  if (count <= 0) return 0;
  final dayOfYear = date.difference(DateTime(date.year)).inDays;
  return dayOfYear % count;
}
