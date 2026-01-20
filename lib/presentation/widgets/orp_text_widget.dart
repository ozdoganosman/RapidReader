/// ORP Text Widget
///
/// Displays a word with the Optimal Recognition Point highlighted.
/// The ORP character is centered on screen and highlighted in a different color.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/utils/orp_calculator.dart';

/// Widget that displays a word with ORP highlighting
///
/// The word is split into three parts:
/// - Before ORP: normal style, right-aligned
/// - ORP character: highlighted (colored/bold), centered
/// - After ORP: normal style, left-aligned
class ORPTextWidget extends StatelessWidget {
  /// The word to display
  final String word;

  /// Font size for the text
  final double fontSize;

  /// Color for normal text
  final Color textColor;

  /// Color for the ORP character
  final Color orpColor;

  /// Font family to use
  final String fontFamily;

  /// Whether to show ORP highlighting
  final bool showHighlight;

  /// Font weight for normal text
  final FontWeight fontWeight;

  /// Font weight for ORP character
  final FontWeight orpFontWeight;

  const ORPTextWidget({
    super.key,
    required this.word,
    this.fontSize = 32,
    this.textColor = Colors.white,
    this.orpColor = Colors.red,
    this.fontFamily = 'Roboto Mono',
    this.showHighlight = true,
    this.fontWeight = FontWeight.w400,
    this.orpFontWeight = FontWeight.bold,
  });

  @override
  Widget build(BuildContext context) {
    if (word.isEmpty) {
      return const SizedBox.shrink();
    }

    final parts = ORPCalculator.splitForDisplay(word);

    // Base text style - use Google Fonts for proper web support
    final baseStyle = _getTextStyle(
      fontSize: fontSize,
      color: textColor,
      fontWeight: fontWeight,
    );

    // ORP character style
    final orpStyle = _getTextStyle(
      fontSize: fontSize,
      color: showHighlight ? orpColor : textColor,
      fontWeight: showHighlight ? orpFontWeight : fontWeight,
    );

    // Calculate character width for monospace alignment
    final charWidth = _measureCharWidth(context, baseStyle);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Before ORP - right aligned to the center point
        SizedBox(
          width: parts.before.length * charWidth,
          child: Text(
            parts.before,
            style: baseStyle,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.visible,
          ),
        ),

        // ORP character - the center point
        Text(
          parts.orp,
          style: orpStyle,
          maxLines: 1,
        ),

        // After ORP - left aligned from the center point
        SizedBox(
          width: parts.after.length * charWidth,
          child: Text(
            parts.after,
            style: baseStyle,
            textAlign: TextAlign.left,
            maxLines: 1,
            overflow: TextOverflow.visible,
          ),
        ),
      ],
    );
  }

  /// Get text style with proper font loading for web
  TextStyle _getTextStyle({
    required double fontSize,
    required Color color,
    required FontWeight fontWeight,
  }) {
    // Use Google Fonts for proper web support with Turkish characters
    if (fontFamily.toLowerCase().contains('mono')) {
      return GoogleFonts.robotoMono(
        fontSize: fontSize,
        color: color,
        fontWeight: fontWeight,
        height: 1.2,
      );
    }

    // Fallback to system font
    return TextStyle(
      fontSize: fontSize,
      fontFamily: fontFamily,
      color: color,
      fontWeight: fontWeight,
      height: 1.2,
    );
  }

  /// Measure the width of a single character in the given style
  double _measureCharWidth(BuildContext context, TextStyle style) {
    // Always measure actual character width using TextPainter
    // This ensures correct width for Google Fonts and Turkish characters
    final textPainter = TextPainter(
      text: TextSpan(text: 'M', style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    return textPainter.width;
  }
}

/// RSVP Display container with focus guides
///
/// Shows the ORP text widget centered with optional focus guide lines
class RSVPDisplay extends StatelessWidget {
  /// The word to display
  final String word;

  /// Font size
  final double fontSize;

  /// Normal text color
  final Color textColor;

  /// ORP highlight color
  final Color orpColor;

  /// Background color
  final Color backgroundColor;

  /// Font family
  final String fontFamily;

  /// Whether to show ORP highlighting
  final bool showHighlight;

  /// Whether to show focus guide lines
  final bool showFocusGuides;

  /// Color for focus guides
  final Color? focusGuideColor;

  const RSVPDisplay({
    super.key,
    required this.word,
    this.fontSize = 32,
    this.textColor = Colors.white,
    this.orpColor = Colors.red,
    this.backgroundColor = Colors.black,
    this.fontFamily = 'Roboto Mono',
    this.showHighlight = true,
    this.showFocusGuides = true,
    this.focusGuideColor,
  });

  @override
  Widget build(BuildContext context) {
    final guideColor = focusGuideColor ?? orpColor.withOpacity(0.5);

    return Container(
      color: backgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Top focus guide
            if (showFocusGuides)
              Container(
                width: 2,
                height: 24,
                color: guideColor,
              ),

            if (showFocusGuides) const SizedBox(height: 12),

            // Word display
            ORPTextWidget(
              word: word,
              fontSize: fontSize,
              textColor: textColor,
              orpColor: orpColor,
              fontFamily: fontFamily,
              showHighlight: showHighlight,
            ),

            if (showFocusGuides) const SizedBox(height: 12),

            // Bottom focus guide
            if (showFocusGuides)
              Container(
                width: 2,
                height: 24,
                color: guideColor,
              ),
          ],
        ),
      ),
    );
  }
}
