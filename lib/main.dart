/// RapidReader - RSVP Speed Reading App
///
/// Main entry point for the application.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/data/quran.dart';
import 'core/services/ad_service.dart';
import 'core/services/app_language.dart';
import 'l10n/app_localizations.dart';
import 'presentation/route_observer.dart';
import 'presentation/screens/home_screen.dart';

/// Fonts for characters the theme's font lacks: Arabic words in titles
/// (surah names) use the bundled Arabic font. In browsers the platform's
/// UI font (Segoe UI, San Francisco) is not available, so Roboto (loaded
/// by the web engine) comes first; otherwise Latin text would be drawn
/// with the Arabic font's Latin letters.
const _fontFallback = [if (kIsWeb) 'Roboto', quranArabicFont];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bundled font license (SIL OFL 1.1) for the licenses page
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Roboto Mono'], license);
    final literata = await rootBundle.loadString('assets/google_fonts/Literata-OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Literata'], literata);
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

  // The language chosen in the settings, if any
  await AppLanguage.load();

  // Ads: the consent message first where needed (not awaited: the app
  // opens meanwhile)
  AdService().initialize();

  runApp(const RapidReaderApp());
}

/// Main application widget
class RapidReaderApp extends StatelessWidget {
  const RapidReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: AppLanguage.choice,
      builder: (context, language, _) => _buildApp(language),
    );
  }

  Widget _buildApp(String? language) {
    return MaterialApp(
      navigatorObservers: [routeObserver],
      title: 'RapidReader',
      // Turkish on Turkish devices, English on all others (or the language
      // chosen in the settings)
      locale: language == null ? null : Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, _) {
        AppLanguage.current = AppLanguage.resolve(locale);
        return Locale(AppLanguage.current);
      },
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamilyFallback: _fontFallback,
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
        fontFamilyFallback: _fontFallback,
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
