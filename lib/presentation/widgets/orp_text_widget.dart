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
/// Uses a simpler approach: RichText with colored ORP character
/// This avoids character clipping issues from width calculations
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

    // Base text style
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

    // Simple approach: Use RichText with three spans
    // This naturally handles character widths without clipping
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(text: parts.before, style: baseStyle),
          TextSpan(text: parts.orp, style: orpStyle),
          TextSpan(text: parts.after, style: baseStyle),
        ],
      ),
    );
  }

  /// Get text style with proper font loading for web
  TextStyle _getTextStyle({
    required double fontSize,
    required Color color,
    required FontWeight fontWeight,
  }) {
    // Use Google Fonts for proper web support with Turkish characters
    switch (fontFamily) {
      case 'Roboto Mono':
        return GoogleFonts.robotoMono(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          height: 1.2,
        );
      case 'Roboto':
        return GoogleFonts.roboto(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          height: 1.2,
        );
      case 'Open Sans':
        return GoogleFonts.openSans(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          height: 1.2,
        );
      case 'Noto Sans':
        return GoogleFonts.notoSans(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          height: 1.2,
        );
      case 'Lato':
        return GoogleFonts.lato(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          height: 1.2,
        );
      case 'Montserrat':
        return GoogleFonts.montserrat(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          height: 1.2,
        );
      case 'Merriweather':
        return GoogleFonts.merriweather(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          height: 1.2,
        );
      case 'Roboto Slab':
        return GoogleFonts.robotoSlab(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          height: 1.2,
        );
      default:
        // Fallback to Roboto Mono
        return GoogleFonts.robotoMono(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          height: 1.2,
        );
    }
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

            // Word display - with padding to prevent any edge clipping
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ORPTextWidget(
                word: word,
                fontSize: fontSize,
                textColor: textColor,
                orpColor: orpColor,
                fontFamily: fontFamily,
                showHighlight: showHighlight,
              ),
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
