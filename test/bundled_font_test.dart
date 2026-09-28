import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the default reading font is bundled, so it needs no download', () async {
    // With runtime fetching off, google_fonts must find the font in the assets
    GoogleFonts.config.allowRuntimeFetching = false;

    for (final file in ['RobotoMono-Regular.ttf', 'RobotoMono-Bold.ttf']) {
      final data = await rootBundle.load('assets/google_fonts/$file');
      expect(data.lengthInBytes, greaterThan(50000));
    }

    GoogleFonts.robotoMono();
    GoogleFonts.robotoMono(fontWeight: FontWeight.bold);
    await GoogleFonts.pendingFonts();
  });
}
