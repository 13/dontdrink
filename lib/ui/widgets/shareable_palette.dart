import 'package:dont_drink/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Forces the light theme for whatever it wraps.
///
/// A shared image is captured from the live screen, so in dark mode it came
/// out as a near-black rectangle — fine on the phone that made it, poor
/// everywhere it is then sent, and unreadable printed or on a light
/// background. Fixing the palette costs one thing worth naming: the preview a
/// dark-mode user sees is no longer pixel-for-pixel what they share. The
/// content is identical, which is the part that matters — nothing appears in
/// the image that was not on screen.
class ShareablePalette extends StatelessWidget {
  const ShareablePalette({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.light(),
      child: Material(
        color: AppTheme.light().colorScheme.surface,
        child: child,
      ),
    );
  }
}
