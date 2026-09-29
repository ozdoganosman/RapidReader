/// RSVP Settings model
///
/// User preferences for RSVP display and reading experience.
library;

import 'package:equatable/equatable.dart';

/// User settings for RSVP reading
class RSVPSettings extends Equatable {
  /// Words per minute (reading speed)
  final int wordsPerMinute;

  /// Number of words to show at once (1-3)
  final int chunkSize;

  /// Whether to apply adaptive speed based on word length
  final bool adaptiveSpeed;

  /// Whether to highlight the ORP character
  final bool showORPHighlight;

  /// Font size for word display
  final double fontSize;

  /// Font family name
  final String fontFamily;

  /// Whether dark mode is enabled
  final bool darkMode;

  /// Number of sentences between micro-pauses
  final int microPauseInterval;

  /// Duration of micro-pause in milliseconds
  final int microPauseDuration;

  /// ORP highlight color (as int)
  final int orpHighlightColor;

  /// Text color (as int)
  final int textColor;

  /// Background color (as int)
  final int backgroundColor;

  /// Whether to show focus guide lines
  final bool showFocusGuides;

  /// Start each play slower and speed up to [wordsPerMinute]
  final bool speedWarmUp;

  /// Speed up by [speedRampStep] every minute of reading until this speed
  /// (WPM); 0: off
  final int speedRampTarget;

  /// The page (plain text): font, size, colors and a
  /// brightness (1.0: none dimmed, down to [minPageBrightness])
  final String pageFontFamily;
  final double pageFontSize;
  final int pageBackgroundColor;
  final int pageTextColor;
  final double pageBrightness;

  const RSVPSettings({
    this.wordsPerMinute = 300,
    this.chunkSize = 1,
    this.adaptiveSpeed = true,
    this.showORPHighlight = true,
    this.fontSize = 32.0,
    this.fontFamily = 'Roboto Mono',
    this.darkMode = true,
    this.microPauseInterval = 7,
    this.microPauseDuration = 300,
    // The colors of [darkTheme], so it is shown as chosen on a new install
    this.orpHighlightColor = 0xFFFF5252, // Light red
    this.textColor = 0xFFFFFFFF, // White
    this.backgroundColor = 0xFF121212, // Dark gray
    this.showFocusGuides = true,
    this.speedWarmUp = true,
    this.speedRampTarget = 0,
    this.pageFontFamily = 'Literata',
    this.pageFontSize = 19,
    this.pageBackgroundColor = 0xFFF8F1E3, // Sepia
    this.pageTextColor = 0xFF3B2F2A,
    this.pageBrightness = 1.0,
  });

  /// Supported page font sizes
  static const minPageFontSize = 14.0;
  static const maxPageFontSize = 32.0;

  /// Least page brightness (the page is dimmed at most to this)
  static const minPageBrightness = 0.3;

  /// Lowest supported reading speed (WPM)
  static const minWordsPerMinute = 100;

  /// Highest supported reading speed (WPM)
  static const maxWordsPerMinute = 1000;

  /// Step used by speed controls (WPM)
  static const wordsPerMinuteStep = 50;

  /// Speed added every minute by the gradual speed-up
  static const speedRampStep = 10;

  /// Default settings
  static const defaults = RSVPSettings();

  /// Light theme preset
  static const lightTheme = RSVPSettings(
    darkMode: false,
    textColor: 0xFF000000, // Black
    backgroundColor: 0xFFFAFAFA, // Light gray
    orpHighlightColor: 0xFFD32F2F, // Dark red
  );

  /// Dark theme preset
  static const darkTheme = RSVPSettings(
    darkMode: true,
    textColor: 0xFFFFFFFF, // White
    backgroundColor: 0xFF121212, // Dark gray
    orpHighlightColor: 0xFFFF5252, // Light red
  );

  /// Sepia theme preset
  static const sepiaTheme = RSVPSettings(
    darkMode: false,
    textColor: 0xFF5D4037, // Brown
    backgroundColor: 0xFFFBF0E4, // Cream
    orpHighlightColor: 0xFFBF360C, // Deep orange
  );

  /// High contrast preset: pure white on black, yellow focus letter
  static const highContrastTheme = RSVPSettings(
    darkMode: true,
    textColor: 0xFFFFFFFF, // White
    backgroundColor: 0xFF000000, // Black
    orpHighlightColor: 0xFFFFD600, // Yellow
  );

  /// Serialize for local storage
  Map<String, dynamic> toMap() => {
        'wordsPerMinute': wordsPerMinute,
        'chunkSize': chunkSize,
        'adaptiveSpeed': adaptiveSpeed,
        'showORPHighlight': showORPHighlight,
        'fontSize': fontSize,
        'fontFamily': fontFamily,
        'darkMode': darkMode,
        'microPauseInterval': microPauseInterval,
        'microPauseDuration': microPauseDuration,
        'orpHighlightColor': orpHighlightColor,
        'textColor': textColor,
        'backgroundColor': backgroundColor,
        'showFocusGuides': showFocusGuides,
        'speedWarmUp': speedWarmUp,
        'speedRampTarget': speedRampTarget,
        'pageFontFamily': pageFontFamily,
        'pageFontSize': pageFontSize,
        'pageBackgroundColor': pageBackgroundColor,
        'pageTextColor': pageTextColor,
        'pageBrightness': pageBrightness,
      };

  /// Restore from local storage
  ///
  /// Missing or invalid values fall back to defaults, and numbers are clamped
  /// to the ranges the settings screen supports.
  factory RSVPSettings.fromMap(Map<dynamic, dynamic> map) {
    const d = RSVPSettings.defaults;

    T read<T>(String key, T fallback) {
      final value = map[key];
      return value is T ? value : fallback;
    }

    final microPauseInterval = read<int>('microPauseInterval', d.microPauseInterval);

    return RSVPSettings(
      wordsPerMinute: read<int>('wordsPerMinute', d.wordsPerMinute).clamp(minWordsPerMinute, maxWordsPerMinute),
      chunkSize: read<int>('chunkSize', d.chunkSize).clamp(1, 3),
      adaptiveSpeed: read<bool>('adaptiveSpeed', d.adaptiveSpeed),
      showORPHighlight: read<bool>('showORPHighlight', d.showORPHighlight),
      fontSize: read<num>('fontSize', d.fontSize).toDouble().clamp(20.0, 60.0),
      fontFamily: read<String>('fontFamily', d.fontFamily),
      darkMode: read<bool>('darkMode', d.darkMode),
      microPauseInterval: microPauseInterval <= 0 ? 0 : microPauseInterval.clamp(3, 15),
      microPauseDuration: read<int>('microPauseDuration', d.microPauseDuration),
      orpHighlightColor: read<int>('orpHighlightColor', d.orpHighlightColor),
      textColor: read<int>('textColor', d.textColor),
      backgroundColor: read<int>('backgroundColor', d.backgroundColor),
      showFocusGuides: read<bool>('showFocusGuides', d.showFocusGuides),
      speedWarmUp: read<bool>('speedWarmUp', d.speedWarmUp),
      speedRampTarget: read<int>('speedRampTarget', d.speedRampTarget).clamp(0, maxWordsPerMinute),
      pageFontFamily: read<String>('pageFontFamily', d.pageFontFamily),
      pageFontSize: read<num>('pageFontSize', d.pageFontSize).toDouble().clamp(minPageFontSize, maxPageFontSize),
      pageBackgroundColor: read<int>('pageBackgroundColor', d.pageBackgroundColor),
      pageTextColor: read<int>('pageTextColor', d.pageTextColor),
      pageBrightness: read<num>('pageBrightness', d.pageBrightness).toDouble().clamp(minPageBrightness, 1.0),
    );
  }

  /// Create a copy with modified fields
  RSVPSettings copyWith({
    int? wordsPerMinute,
    int? chunkSize,
    bool? adaptiveSpeed,
    bool? showORPHighlight,
    double? fontSize,
    String? fontFamily,
    bool? darkMode,
    int? microPauseInterval,
    int? microPauseDuration,
    int? orpHighlightColor,
    int? textColor,
    int? backgroundColor,
    bool? showFocusGuides,
    bool? speedWarmUp,
    int? speedRampTarget,
    String? pageFontFamily,
    double? pageFontSize,
    int? pageBackgroundColor,
    int? pageTextColor,
    double? pageBrightness,
  }) {
    return RSVPSettings(
      wordsPerMinute: wordsPerMinute ?? this.wordsPerMinute,
      chunkSize: chunkSize ?? this.chunkSize,
      adaptiveSpeed: adaptiveSpeed ?? this.adaptiveSpeed,
      showORPHighlight: showORPHighlight ?? this.showORPHighlight,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      darkMode: darkMode ?? this.darkMode,
      microPauseInterval: microPauseInterval ?? this.microPauseInterval,
      microPauseDuration: microPauseDuration ?? this.microPauseDuration,
      orpHighlightColor: orpHighlightColor ?? this.orpHighlightColor,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      showFocusGuides: showFocusGuides ?? this.showFocusGuides,
      speedWarmUp: speedWarmUp ?? this.speedWarmUp,
      speedRampTarget: speedRampTarget ?? this.speedRampTarget,
      pageFontFamily: pageFontFamily ?? this.pageFontFamily,
      pageFontSize: pageFontSize ?? this.pageFontSize,
      pageBackgroundColor: pageBackgroundColor ?? this.pageBackgroundColor,
      pageTextColor: pageTextColor ?? this.pageTextColor,
      pageBrightness: pageBrightness ?? this.pageBrightness,
    );
  }

  @override
  List<Object?> get props => [
        wordsPerMinute,
        chunkSize,
        adaptiveSpeed,
        showORPHighlight,
        fontSize,
        fontFamily,
        darkMode,
        microPauseInterval,
        microPauseDuration,
        orpHighlightColor,
        textColor,
        backgroundColor,
        showFocusGuides,
        speedWarmUp,
        speedRampTarget,
        pageFontFamily,
        pageFontSize,
        pageBackgroundColor,
        pageTextColor,
        pageBrightness,
      ];
}
