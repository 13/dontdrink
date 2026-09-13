import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Why sharing an image failed. Wording lives in the .arb files, like every
/// other failure that starts below the widget layer.
enum ShareFailure {
  /// The widget was not on screen, so there was nothing to capture.
  nothingToCapture,

  /// Encoding the picture to PNG produced nothing.
  encodingFailed,

  /// Writing the file or handing it to the share sheet threw.
  handoffFailed,
}

class ShareImageException implements Exception {
  const ShareImageException(this.failure, {this.detail});

  final ShareFailure failure;
  final String? detail;

  @override
  String toString() =>
      'ShareImageException(${failure.name}${detail == null ? '' : ': $detail'})';
}

/// Turns a piece of the screen into a PNG and hands it to the system share
/// sheet.
///
/// The caller wraps whatever should be shared in a [RepaintBoundary] and
/// passes its key, so what gets shared is exactly what was on screen — there
/// is no second, invisible layout that could quietly include something the
/// user never saw.
class ShareImageService {
  const ShareImageService();

  /// Capture the boundary behind [key] and open the share sheet.
  ///
  /// [fileName] is what the receiving app sees, so it carries the period
  /// rather than a timestamp.
  Future<void> shareBoundary({
    required GlobalKey key,
    required String fileName,
    double pixelRatio = 3,
  }) async {
    final bytes = await capture(key: key, pixelRatio: pixelRatio);

    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName.png');
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles([XFile(file.path, mimeType: 'image/png')]);
    } catch (e) {
      throw ShareImageException(ShareFailure.handoffFailed, detail: '$e');
    }
  }

  /// The PNG bytes for the boundary behind [key]. Separate from the share so
  /// it can be tested without a share sheet.
  Future<Uint8List> capture({
    required GlobalKey key,
    double pixelRatio = 3,
  }) async {
    final context = key.currentContext;
    final object = context?.findRenderObject();
    if (context == null || object is! RenderRepaintBoundary) {
      // The widget is not mounted — the screen was left before the capture
      // started, so there is nothing to photograph.
      throw const ShareImageException(ShareFailure.nothingToCapture);
    }

    final ui.Image image = await object.toImage(pixelRatio: pixelRatio);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) {
        throw const ShareImageException(ShareFailure.encodingFailed);
      }
      return data.buffer.asUint8List();
    } finally {
      // The raw image holds native memory that the garbage collector does not
      // account for; a few unshared captures would otherwise add up.
      image.dispose();
    }
  }
}
