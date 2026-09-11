import 'package:google_fonts/google_fonts.dart';

/// Inter is bundled in assets/fonts/, so google_fonts must never reach out to
/// fonts.gstatic.com. The app's About card tells the user it contacts only
/// GitHub; this is what makes that true.
void configureBundledFonts() {
  GoogleFonts.config.allowRuntimeFetching = false;
}
