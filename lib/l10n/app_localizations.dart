import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr')
  ];

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @modeSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed Reading'**
  String get modeSpeed;

  /// No description provided for @modeSpeedHint.
  ///
  /// In en, this message translates to:
  /// **'Word by word, at your speed'**
  String get modeSpeedHint;

  /// No description provided for @modePlain.
  ///
  /// In en, this message translates to:
  /// **'Plain Text'**
  String get modePlain;

  /// No description provided for @modePlainHint.
  ///
  /// In en, this message translates to:
  /// **'As a page, at your own pace'**
  String get modePlainHint;

  /// No description provided for @continueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueReading;

  /// No description provided for @continueProgress.
  ///
  /// In en, this message translates to:
  /// **'{percent}% · {mode}'**
  String continueProgress(int percent, String mode);

  /// No description provided for @sharedContentUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the shared content'**
  String get sharedContentUnreadable;

  /// No description provided for @library.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get library;

  /// No description provided for @readingSpeed.
  ///
  /// In en, this message translates to:
  /// **'Reading Speed'**
  String get readingSpeed;

  /// No description provided for @wordsPerMinuteShort.
  ///
  /// In en, this message translates to:
  /// **'words/min'**
  String get wordsPerMinuteShort;

  /// No description provided for @adjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust'**
  String get adjust;

  /// No description provided for @quranCardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Translated by M. Pickthall'**
  String get quranCardSubtitle;

  /// No description provided for @chaptersAndTime.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 chapter} other{{count} chapters}} · {time}'**
  String chaptersAndTime(int count, String time);

  /// No description provided for @wordCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 word} other{{count} words}}'**
  String wordCount(int count);

  /// No description provided for @addText.
  ///
  /// In en, this message translates to:
  /// **'Add Text'**
  String get addText;

  /// No description provided for @addTextHint.
  ///
  /// In en, this message translates to:
  /// **'Add your own text'**
  String get addTextHint;

  /// No description provided for @addTextTitle.
  ///
  /// In en, this message translates to:
  /// **'Add New Text'**
  String get addTextTitle;

  /// No description provided for @addCoverOptional.
  ///
  /// In en, this message translates to:
  /// **'Add Cover Image (Optional)'**
  String get addCoverOptional;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title *'**
  String get titleLabel;

  /// No description provided for @titleMissing.
  ///
  /// In en, this message translates to:
  /// **'A title is required'**
  String get titleMissing;

  /// No description provided for @authorLabel.
  ///
  /// In en, this message translates to:
  /// **'Author (Optional)'**
  String get authorLabel;

  /// No description provided for @fileUnreadableWithError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the file: {error}'**
  String fileUnreadableWithError(String error);

  /// No description provided for @readingFile.
  ///
  /// In en, this message translates to:
  /// **'Reading the file…'**
  String get readingFile;

  /// No description provided for @importFromFile.
  ///
  /// In en, this message translates to:
  /// **'Import from File (TXT, PDF, EPUB)'**
  String get importFromFile;

  /// No description provided for @fromClipboard.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get fromClipboard;

  /// No description provided for @clipboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'There is no text on the clipboard'**
  String get clipboardEmpty;

  /// No description provided for @webAddress.
  ///
  /// In en, this message translates to:
  /// **'Web Address'**
  String get webAddress;

  /// No description provided for @contentLabel.
  ///
  /// In en, this message translates to:
  /// **'Text *'**
  String get contentLabel;

  /// No description provided for @contentMissing.
  ///
  /// In en, this message translates to:
  /// **'Text is required'**
  String get contentMissing;

  /// No description provided for @readWithoutSaving.
  ///
  /// In en, this message translates to:
  /// **'Read Without Saving'**
  String get readWithoutSaving;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the text. It may be too large for the device\'s storage.'**
  String get saveFailed;

  /// No description provided for @textAdded.
  ///
  /// In en, this message translates to:
  /// **'Text added!'**
  String get textAdded;

  /// No description provided for @webArticle.
  ///
  /// In en, this message translates to:
  /// **'Web article'**
  String get webArticle;

  /// No description provided for @fetch.
  ///
  /// In en, this message translates to:
  /// **'Fetch'**
  String get fetch;

  /// No description provided for @pageUnreadableWithError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the page: {error}'**
  String pageUnreadableWithError(String error);

  /// No description provided for @deleteText.
  ///
  /// In en, this message translates to:
  /// **'Delete Text'**
  String get deleteText;

  /// No description provided for @deleteTextConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{title}\"?'**
  String deleteTextConfirm(String title);

  /// No description provided for @textDeleted.
  ///
  /// In en, this message translates to:
  /// **'Text deleted'**
  String get textDeleted;

  /// No description provided for @durationSeconds.
  ///
  /// In en, this message translates to:
  /// **'{seconds} s'**
  String durationSeconds(int seconds);

  /// No description provided for @durationMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// No description provided for @durationMinutesSeconds.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min {seconds} s'**
  String durationMinutesSeconds(int minutes, int seconds);

  /// No description provided for @durationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours} h'**
  String durationHours(int hours);

  /// No description provided for @durationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String durationHoursMinutes(int hours, int minutes);

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @unsavedChanges.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Changes'**
  String get unsavedChanges;

  /// No description provided for @unsavedChangesBody.
  ///
  /// In en, this message translates to:
  /// **'Your changes to the settings are not saved. What would you like to do?'**
  String get unsavedChangesBody;

  /// No description provided for @discardAndExit.
  ///
  /// In en, this message translates to:
  /// **'Exit (Don\'t Save)'**
  String get discardAndExit;

  /// No description provided for @saveAndExit.
  ///
  /// In en, this message translates to:
  /// **'Save and Exit'**
  String get saveAndExit;

  /// No description provided for @wordsPerMinuteLabel.
  ///
  /// In en, this message translates to:
  /// **'Words per minute (WPM)'**
  String get wordsPerMinuteLabel;

  /// No description provided for @adaptiveSpeed.
  ///
  /// In en, this message translates to:
  /// **'Adaptive Speed'**
  String get adaptiveSpeed;

  /// No description provided for @adaptiveSpeedHint.
  ///
  /// In en, this message translates to:
  /// **'Short words faster, long words slower'**
  String get adaptiveSpeedHint;

  /// No description provided for @speedWarmUp.
  ///
  /// In en, this message translates to:
  /// **'Speed Warm-up'**
  String get speedWarmUp;

  /// No description provided for @speedWarmUpHint.
  ///
  /// In en, this message translates to:
  /// **'Start slow, reach your speed in a few seconds'**
  String get speedWarmUpHint;

  /// No description provided for @speedRamp.
  ///
  /// In en, this message translates to:
  /// **'Gradual Speed-up'**
  String get speedRamp;

  /// No description provided for @speedRampHint.
  ///
  /// In en, this message translates to:
  /// **'While you read, the speed rises by {step} words every minute and stops at the target'**
  String speedRampHint(int step);

  /// No description provided for @targetSpeed.
  ///
  /// In en, this message translates to:
  /// **'Target Speed'**
  String get targetSpeed;

  /// No description provided for @wordGrouping.
  ///
  /// In en, this message translates to:
  /// **'Word Grouping'**
  String get wordGrouping;

  /// No description provided for @chunkSize.
  ///
  /// In en, this message translates to:
  /// **'Chunk Size'**
  String get chunkSize;

  /// No description provided for @display.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get display;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSize;

  /// No description provided for @orpHighlight.
  ///
  /// In en, this message translates to:
  /// **'ORP Highlight'**
  String get orpHighlight;

  /// No description provided for @orpHighlightHint.
  ///
  /// In en, this message translates to:
  /// **'Highlight the focus letter in red'**
  String get orpHighlightHint;

  /// No description provided for @focusGuides.
  ///
  /// In en, this message translates to:
  /// **'Focus Guides'**
  String get focusGuides;

  /// No description provided for @focusGuidesHint.
  ///
  /// In en, this message translates to:
  /// **'Show the vertical alignment lines'**
  String get focusGuidesHint;

  /// No description provided for @fontFamily.
  ///
  /// In en, this message translates to:
  /// **'Font Family'**
  String get fontFamily;

  /// No description provided for @fontMonoHint.
  ///
  /// In en, this message translates to:
  /// **'Monospace - Fixed width'**
  String get fontMonoHint;

  /// No description provided for @fontRobotoHint.
  ///
  /// In en, this message translates to:
  /// **'Sans-serif - Modern'**
  String get fontRobotoHint;

  /// No description provided for @fontOpenSansHint.
  ///
  /// In en, this message translates to:
  /// **'Sans-serif - Readable'**
  String get fontOpenSansHint;

  /// No description provided for @fontNotoSansHint.
  ///
  /// In en, this message translates to:
  /// **'Sans-serif - Multilingual'**
  String get fontNotoSansHint;

  /// No description provided for @fontLatoHint.
  ///
  /// In en, this message translates to:
  /// **'Sans-serif - Elegant'**
  String get fontLatoHint;

  /// No description provided for @fontMontserratHint.
  ///
  /// In en, this message translates to:
  /// **'Sans-serif - Bold'**
  String get fontMontserratHint;

  /// No description provided for @fontMerriweatherHint.
  ///
  /// In en, this message translates to:
  /// **'Serif - Classic'**
  String get fontMerriweatherHint;

  /// No description provided for @fontRobotoSlabHint.
  ///
  /// In en, this message translates to:
  /// **'Slab Serif - Strong'**
  String get fontRobotoSlabHint;

  /// No description provided for @fontOpenDyslexicHint.
  ///
  /// In en, this message translates to:
  /// **'Dyslexia friendly - Letters don\'t mix up'**
  String get fontOpenDyslexicHint;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeSepia.
  ///
  /// In en, this message translates to:
  /// **'Sepia'**
  String get themeSepia;

  /// No description provided for @themeHighContrast.
  ///
  /// In en, this message translates to:
  /// **'High Contrast'**
  String get themeHighContrast;

  /// No description provided for @cognitivePause.
  ///
  /// In en, this message translates to:
  /// **'Cognitive Pause'**
  String get cognitivePause;

  /// No description provided for @microPause.
  ///
  /// In en, this message translates to:
  /// **'Micro-pause'**
  String get microPause;

  /// No description provided for @microPauseEvery.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{A pause after every sentence} other{A pause every {count} sentences}}'**
  String microPauseEvery(int count);

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @pauseInterval.
  ///
  /// In en, this message translates to:
  /// **'Pause Interval'**
  String get pauseInterval;

  /// No description provided for @sentenceCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 sentence} other{{count} sentences}}'**
  String sentenceCount(int count);

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @adConsent.
  ///
  /// In en, this message translates to:
  /// **'Ad consent'**
  String get adConsent;

  /// No description provided for @adConsentHint.
  ///
  /// In en, this message translates to:
  /// **'Change the consent for ads with personal data'**
  String get adConsentHint;

  /// No description provided for @resetDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to Defaults'**
  String get resetDefaults;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageDevice.
  ///
  /// In en, this message translates to:
  /// **'Device language'**
  String get languageDevice;

  /// No description provided for @readingComplete.
  ///
  /// In en, this message translates to:
  /// **'Finished!'**
  String get readingComplete;

  /// No description provided for @remainingAndTotal.
  ///
  /// In en, this message translates to:
  /// **'Left: {remaining} / Total: {total}'**
  String remainingAndTotal(String remaining, String total);

  /// No description provided for @tapLeftEdgeHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the left edge: back to the sentence start'**
  String get tapLeftEdgeHint;

  /// No description provided for @pageView.
  ///
  /// In en, this message translates to:
  /// **'Page View'**
  String get pageView;

  /// No description provided for @wordPosition.
  ///
  /// In en, this message translates to:
  /// **'Word {current} / {total}'**
  String wordPosition(int current, int total);

  /// No description provided for @chapterComplete.
  ///
  /// In en, this message translates to:
  /// **'Chapter Finished!'**
  String get chapterComplete;

  /// No description provided for @nextChapter.
  ///
  /// In en, this message translates to:
  /// **'Next Chapter'**
  String get nextChapter;

  /// No description provided for @backToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// No description provided for @searchSurah.
  ///
  /// In en, this message translates to:
  /// **'Search surahs (name or number)'**
  String get searchSurah;

  /// No description provided for @revelationOrder.
  ///
  /// In en, this message translates to:
  /// **'Revelation order'**
  String get revelationOrder;

  /// No description provided for @mushafOrder.
  ///
  /// In en, this message translates to:
  /// **'Mushaf order'**
  String get mushafOrder;

  /// No description provided for @revelationNumber.
  ///
  /// In en, this message translates to:
  /// **'Revelation {number}'**
  String revelationNumber(int number);

  /// No description provided for @mushafNumber.
  ///
  /// In en, this message translates to:
  /// **'Mushaf {number}'**
  String mushafNumber(int number);

  /// No description provided for @arabicText.
  ///
  /// In en, this message translates to:
  /// **'Arabic text'**
  String get arabicText;

  /// No description provided for @arabicTextUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the Arabic text'**
  String get arabicTextUnavailable;

  /// No description provided for @arabicTextSource.
  ///
  /// In en, this message translates to:
  /// **'Arabic text: Tanzil Project (tanzil.net), used unchanged. CC BY 3.0'**
  String get arabicTextSource;

  /// No description provided for @pageSettings.
  ///
  /// In en, this message translates to:
  /// **'Page settings'**
  String get pageSettings;

  /// No description provided for @guidedReading.
  ///
  /// In en, this message translates to:
  /// **'Guided reading'**
  String get guidedReading;

  /// No description provided for @stopGuidedReading.
  ///
  /// In en, this message translates to:
  /// **'Stop guided reading'**
  String get stopGuidedReading;

  /// No description provided for @slower.
  ///
  /// In en, this message translates to:
  /// **'Slower'**
  String get slower;

  /// No description provided for @faster.
  ///
  /// In en, this message translates to:
  /// **'Faster'**
  String get faster;

  /// No description provided for @pageThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get pageThemeLight;

  /// No description provided for @pageThemeSepia.
  ///
  /// In en, this message translates to:
  /// **'Sepia'**
  String get pageThemeSepia;

  /// No description provided for @pageThemeGray.
  ///
  /// In en, this message translates to:
  /// **'Gray'**
  String get pageThemeGray;

  /// No description provided for @pageThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get pageThemeDark;

  /// No description provided for @pageThemeNight.
  ///
  /// In en, this message translates to:
  /// **'Night'**
  String get pageThemeNight;

  /// No description provided for @pageFont.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get pageFont;

  /// No description provided for @pageTextSize.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get pageTextSize;

  /// No description provided for @pageBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get pageBackground;

  /// No description provided for @pageTextColor.
  ///
  /// In en, this message translates to:
  /// **'Text color'**
  String get pageTextColor;

  /// No description provided for @pageBrightness.
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get pageBrightness;

  /// No description provided for @enterValidUrl.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid web address (https://...)'**
  String get enterValidUrl;

  /// No description provided for @siteBlockedInBrowser.
  ///
  /// In en, this message translates to:
  /// **'The browser\'s security rules don\'t allow reading this site. Use the Android app, or copy the text and use \"Paste\".'**
  String get siteBlockedInBrowser;

  /// No description provided for @pageDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t download the page. Check your internet connection.'**
  String get pageDownloadFailed;

  /// No description provided for @pageOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the page (HTTP {status})'**
  String pageOpenFailed(int status);

  /// No description provided for @noTextOnPage.
  ///
  /// In en, this message translates to:
  /// **'No readable text found on the page'**
  String get noTextOnPage;

  /// No description provided for @fileUnreadable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the file'**
  String get fileUnreadable;

  /// No description provided for @unsupportedFileType.
  ///
  /// In en, this message translates to:
  /// **'Unsupported file type: .{extension}'**
  String unsupportedFileType(String extension);

  /// No description provided for @noTextInFile.
  ///
  /// In en, this message translates to:
  /// **'No readable text found in the file'**
  String get noTextInFile;

  /// No description provided for @percent.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String percent(int value);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
