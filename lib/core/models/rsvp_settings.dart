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
    this.orpHighlightColor = 0xFFFF0000, // Red
    this.textColor = 0xFFFFFFFF, // White
    this.backgroundColor = 0xFF000000, // Black
    this.showFocusGuides = true,
  });

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
      ];
}
