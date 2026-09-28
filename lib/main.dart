/// RapidReader - RSVP Speed Reading App
///
/// Main entry point for the application.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/data/quran.dart';
import 'core/services/ad_service.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bundled font license (SIL OFL 1.1) for the licenses page
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Roboto Mono'], license);
    final amiri = await rootBundle.loadString('assets/fonts/AmiriQuran-OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Amiri Quran'], amiri);
    final openDyslexic = await rootBundle.loadString('assets/fonts/OpenDyslexic-LICENSE.txt');
    yield LicenseEntryWithLineBreaks(const ['OpenDyslexic'], openDyslexic);
  });

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize ads
  await AdService().initialize();

  runApp(const RapidReaderApp());
}

/// Main application widget
class RapidReaderApp extends StatelessWidget {
  const RapidReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RapidReader',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Arabic words in titles (surah names) use the bundled Arabic font
        fontFamilyFallback: const [quranArabicFont],
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      darkTheme: ThemeData(
        fontFamilyFallback: const [quranArabicFont],
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
