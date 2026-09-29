// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get modeSpeed => 'Speed Reading';

  @override
  String get modeSpeedHint => 'Word by word, at your speed';

  @override
  String get modePlain => 'Plain Text';

  @override
  String get modePlainHint => 'As a page, at your own pace';

  @override
  String get continueReading => 'Continue';

  @override
  String continueProgress(int percent, String mode) {
    return '$percent% · $mode';
  }

  @override
  String get sharedContentUnreadable => 'Couldn\'t read the shared content';

  @override
  String get library => 'Library';

  @override
  String get readingSpeed => 'Reading Speed';

  @override
  String get wordsPerMinuteShort => 'words/min';

  @override
  String get adjust => 'Adjust';

  @override
  String get quranCardSubtitle => 'Translated by M. Pickthall';

  @override
  String chaptersAndTime(int count, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chapters',
      one: '1 chapter',
    );
    return '$_temp0 · $time';
  }

  @override
  String wordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count words',
      one: '1 word',
    );
    return '$_temp0';
  }

  @override
  String get addText => 'Add Text';

  @override
  String get addTextHint => 'Add your own text';

  @override
  String get addTextTitle => 'Add New Text';

  @override
  String get addCoverOptional => 'Add Cover Image (Optional)';

  @override
  String get titleLabel => 'Title *';

  @override
  String get titleMissing => 'A title is required';

  @override
  String get authorLabel => 'Author (Optional)';

  @override
  String fileUnreadableWithError(String error) {
    return 'Couldn\'t read the file: $error';
  }

  @override
  String get readingFile => 'Reading the file…';

  @override
  String get importFromFile => 'Import from File (TXT, PDF, EPUB)';

  @override
  String get fromClipboard => 'Paste';

  @override
  String get clipboardEmpty => 'There is no text on the clipboard';

  @override
  String get webAddress => 'Web Address';

  @override
  String get contentLabel => 'Text *';

  @override
  String get contentMissing => 'Text is required';

  @override
  String get readWithoutSaving => 'Read Without Saving';

  @override
  String get saveFailed =>
      'Couldn\'t save the text. It may be too large for the device\'s storage.';

  @override
  String get textAdded => 'Text added!';

  @override
  String get webArticle => 'Web article';

  @override
  String get fetch => 'Fetch';

  @override
  String pageUnreadableWithError(String error) {
    return 'Couldn\'t read the page: $error';
  }

  @override
  String get deleteText => 'Delete Text';

  @override
  String deleteTextConfirm(String title) {
    return 'Are you sure you want to delete \"$title\"?';
  }

  @override
  String get textDeleted => 'Text deleted';

  @override
  String durationSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String durationMinutesSeconds(int minutes, int seconds) {
    return '$minutes min $seconds s';
  }

  @override
  String durationHours(int hours) {
    return '$hours h';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get settings => 'Settings';

  @override
  String get unsavedChanges => 'Unsaved Changes';

  @override
  String get unsavedChangesBody =>
      'Your changes to the settings are not saved. What would you like to do?';

  @override
  String get discardAndExit => 'Exit (Don\'t Save)';

  @override
  String get saveAndExit => 'Save and Exit';

  @override
  String get wordsPerMinuteLabel => 'Words per minute (WPM)';

  @override
  String get adaptiveSpeed => 'Adaptive Speed';

  @override
  String get adaptiveSpeedHint => 'Short words faster, long words slower';

  @override
  String get speedWarmUp => 'Speed Warm-up';

  @override
  String get speedWarmUpHint => 'Start slow, reach your speed in a few seconds';

  @override
  String get speedRamp => 'Gradual Speed-up';

  @override
  String speedRampHint(int step) {
    return 'While you read, the speed rises by $step words every minute and stops at the target';
  }

  @override
  String get targetSpeed => 'Target Speed';

  @override
  String get wordGrouping => 'Word Grouping';

  @override
  String get chunkSize => 'Chunk Size';

  @override
  String get display => 'Display';

  @override
  String get fontSize => 'Font Size';

  @override
  String get orpHighlight => 'ORP Highlight';

  @override
  String get orpHighlightHint => 'Highlight the focus letter in red';

  @override
  String get focusGuides => 'Focus Guides';

  @override
  String get focusGuidesHint => 'Show the vertical alignment lines';

  @override
  String get fontFamily => 'Font Family';

  @override
  String get fontMonoHint => 'Monospace - Fixed width';

  @override
  String get fontRobotoHint => 'Sans-serif - Modern';

  @override
  String get fontOpenSansHint => 'Sans-serif - Readable';

  @override
  String get fontNotoSansHint => 'Sans-serif - Multilingual';

  @override
  String get fontLatoHint => 'Sans-serif - Elegant';

  @override
  String get fontMontserratHint => 'Sans-serif - Bold';

  @override
  String get fontMerriweatherHint => 'Serif - Classic';

  @override
  String get fontRobotoSlabHint => 'Slab Serif - Strong';

  @override
  String get fontOpenDyslexicHint =>
      'Dyslexia friendly - Letters don\'t mix up';

  @override
  String get theme => 'Theme';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get themeSepia => 'Sepia';

  @override
  String get themeHighContrast => 'High Contrast';

  @override
  String get cognitivePause => 'Cognitive Pause';

  @override
  String get microPause => 'Micro-pause';

  @override
  String microPauseEvery(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'A pause every $count sentences',
      one: 'A pause after every sentence',
    );
    return '$_temp0';
  }

  @override
  String get off => 'Off';

  @override
  String get pauseInterval => 'Pause Interval';

  @override
  String sentenceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sentences',
      one: '1 sentence',
    );
    return '$_temp0';
  }

  @override
  String get privacy => 'Privacy';

  @override
  String get adConsent => 'Ad consent';

  @override
  String get adConsentHint => 'Change the consent for ads with personal data';

  @override
  String get resetDefaults => 'Reset to Defaults';

  @override
  String get language => 'Language';

  @override
  String get languageDevice => 'Device language';

  @override
  String get readingComplete => 'Finished!';

  @override
  String remainingAndTotal(String remaining, String total) {
    return 'Left: $remaining / Total: $total';
  }

  @override
  String get tapLeftEdgeHint => 'Tap the left edge: back to the sentence start';

  @override
  String get pageView => 'Page View';

  @override
  String wordPosition(int current, int total) {
    return 'Word $current / $total';
  }

  @override
  String get chapterComplete => 'Chapter Finished!';

  @override
  String get nextChapter => 'Next Chapter';

  @override
  String get backToHome => 'Back to Home';

  @override
  String get searchSurah => 'Search surahs (name or number)';

  @override
  String get revelationOrder => 'Revelation order';

  @override
  String get mushafOrder => 'Mushaf order';

  @override
  String revelationNumber(int number) {
    return 'Revelation $number';
  }

  @override
  String mushafNumber(int number) {
    return 'Mushaf $number';
  }

  @override
  String get arabicText => 'Arabic text';

  @override
  String get arabicTextUnavailable => 'Couldn\'t load the Arabic text';

  @override
  String get arabicTextSource =>
      'Arabic text: Tanzil Project (tanzil.net), used unchanged. CC BY 3.0';

  @override
  String get pageSettings => 'Page settings';

  @override
  String get guidedReading => 'Guided reading';

  @override
  String get stopGuidedReading => 'Stop guided reading';

  @override
  String get slower => 'Slower';

  @override
  String get faster => 'Faster';

  @override
  String get pageThemeLight => 'Light';

  @override
  String get pageThemeSepia => 'Sepia';

  @override
  String get pageThemeGray => 'Gray';

  @override
  String get pageThemeDark => 'Dark';

  @override
  String get pageThemeNight => 'Night';

  @override
  String get pageFont => 'Font';

  @override
  String get pageTextSize => 'Text size';

  @override
  String get pageBackground => 'Background';

  @override
  String get pageTextColor => 'Text color';

  @override
  String get pageBrightness => 'Brightness';

  @override
  String get enterValidUrl => 'Enter a valid web address (https://...)';

  @override
  String get siteBlockedInBrowser =>
      'The browser\'s security rules don\'t allow reading this site. Use the Android app, or copy the text and use \"Paste\".';

  @override
  String get pageDownloadFailed =>
      'Couldn\'t download the page. Check your internet connection.';

  @override
  String pageOpenFailed(int status) {
    return 'Couldn\'t open the page (HTTP $status)';
  }

  @override
  String get noTextOnPage => 'No readable text found on the page';

  @override
  String get fileUnreadable => 'Couldn\'t read the file';

  @override
  String unsupportedFileType(String extension) {
    return 'Unsupported file type: .$extension';
  }

  @override
  String get noTextInFile => 'No readable text found in the file';

  @override
  String percent(int value) {
    return '$value%';
  }
}
