import 'package:dont_drink/core/theme/app_colors.dart';
import 'package:dont_drink/l10n/app_localizations.dart';
import 'package:dont_drink/services/achievement_service.dart';
import 'package:dont_drink/ui/widgets/share_image_button.dart';
import 'package:flutter/material.dart';

/// Shows a badge as the card it will be shared as, with the share action on
/// it.
///
/// The preview *is* the artifact: what the user looks at here is exactly the
/// image that leaves the device, so nothing can end up in it that they have
/// not already seen. In keeping with the rest of sharing, it carries the badge
/// and the mode it belongs to — no streak numbers, no dates, no rates.
class BadgeShareDialog extends StatefulWidget {
  const BadgeShareDialog({
    super.key,
    required this.status,
    required this.modeName,
  });

  final AchievementStatus status;

  /// Which habit the badge belongs to, so a shared card says what it is for.
  final String modeName;

  static Future<void> show(
    BuildContext context, {
    required AchievementStatus status,
    required String modeName,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => BadgeShareDialog(status: status, modeName: modeName),
    );
  }

  @override
  State<BadgeShareDialog> createState() => _BadgeShareDialogState();
}

class _BadgeShareDialogState extends State<BadgeShareDialog> {
  final _shareKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final achievement = widget.status.achievement;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            key: _shareKey,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.brand, AppColors.brandDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(achievement.emoji,
                      style: const TextStyle(fontSize: 64)),
                  const SizedBox(height: 12),
                  Text(
                    achievement.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.badgeDayThreshold(achievement.dayThreshold),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                  if (widget.status.isRepeated) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        l10n.badgeTimesChip(widget.status.earnedCount),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    widget.modeName,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.comfortClose),
                ),
                ShareImageButton(
                  boundaryKey: _shareKey,
                  fileName: 'dont-drink-badge-${achievement.id}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
