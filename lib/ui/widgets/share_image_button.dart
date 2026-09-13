import 'package:dont_drink/l10n/app_localizations.dart';
import 'package:dont_drink/services/share_image_service.dart';
import 'package:flutter/material.dart';

/// Share whatever sits inside the [RepaintBoundary] behind [boundaryKey].
///
/// What is captured is what is on screen — there is no second, off-screen
/// layout that could put something in the image the user never saw.
class ShareImageButton extends StatefulWidget {
  const ShareImageButton({
    super.key,
    required this.boundaryKey,
    required this.fileName,
    this.service = const ShareImageService(),
  });

  final GlobalKey boundaryKey;

  /// Name the receiving app sees, without the extension.
  final String fileName;

  final ShareImageService service;

  @override
  State<ShareImageButton> createState() => _ShareImageButtonState();
}

class _ShareImageButtonState extends State<ShareImageButton> {
  bool _busy = false;

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.service.shareBoundary(
        key: widget.boundaryKey,
        fileName: widget.fileName,
      );
    } catch (_) {
      // Every failure reads the same to the user: the picture did not go
      // anywhere. The detail is for the log, not for a snackbar.
      messenger.showSnackBar(SnackBar(content: Text(l10n.shareFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      onPressed: _busy ? null : _share,
      tooltip: l10n.shareImage,
      icon: _busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.ios_share),
    );
  }
}
