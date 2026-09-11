import 'package:dont_drink/core/theme/app_theme.dart';
import 'package:dont_drink/core/theme/font_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('configureBundledFonts disables runtime fetching', () {
    // Flip it back on first, so the assertion below actually exercises
    // configureBundledFonts() rather than passing on a default.
    GoogleFonts.config.allowRuntimeFetching = true;
    configureBundledFonts();
    expect(GoogleFonts.config.allowRuntimeFetching, isFalse);
  });

  test(
      'AppTheme builds without google_fonts falling back to fetching or Roboto',
      () async {
    final captured = <String?>[];
    final originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      captured.add(message);
    };

    try {
      configureBundledFonts();
      AppTheme.light();
      AppTheme.dark();
      // GoogleFonts.inter()/interTextTheme() kick off font loading in the
      // background without awaiting it; wait for it to settle so a failure
      // has had the chance to debugPrint before we check.
      await GoogleFonts.pendingFonts();
    } finally {
      debugPrint = originalDebugPrint;
    }

    final loadFailures = captured.where(
      (m) => m != null && m.contains('google_fonts was unable to load'),
    );
    expect(loadFailures, isEmpty,
        reason: 'a load failure here means the Inter asset is missing or '
            'misnamed, and google_fonts silently degraded to Roboto instead '
            'of contacting fonts.gstatic.com');
  });
}
