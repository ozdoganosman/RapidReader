/// App Language
///
/// The app is in Turkish on Turkish devices and in English everywhere else,
/// unless a language is chosen in the settings. The language also picks the
/// bundled library (Turkish or English texts).
library;

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';

class AppLanguage {
  static const supported = ['tr', 'en'];
  static const _key = 'app_language';

  /// The language chosen in the settings; null: the device's language
  static final choice = ValueNotifier<String?>(null);

  /// The language in use, set when the app resolves its locale
  static String current = 'tr';

  /// The language for the device's [locale]: the chosen one, or Turkish
  /// for Turkish devices and English for all others
  static String resolve(Locale? locale) => choice.value ?? (locale?.languageCode == 'tr' ? 'tr' : 'en');

  /// Texts in the current language, for code without a BuildContext
  static AppLocalizations get strings => lookupAppLocalizations(Locale(current));

  static Future<void> load() async {
    final saved = (await SharedPreferences.getInstance()).getString(_key);
    choice.value = supported.contains(saved) ? saved : null;
  }

  static Future<void> choose(String? language) async {
    choice.value = language;
    final prefs = await SharedPreferences.getInstance();
    language == null ? await prefs.remove(_key) : await prefs.setString(_key, language);
  }
}

extension AppLocalizationsContext on BuildContext {
  /// The app's texts in the current language
  AppLocalizations get l10n => AppLocalizations.of(this);
}
