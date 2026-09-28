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
    final textScaler = MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling;

    return LayoutBuilder(
      builder: (context, constraints) {
        var size = fontSize;
        var layout = _measure(parts, size, textScaler);

        // Shrink long words (or chunks) so they fit instead of overflowing.
        // Leave room for the rounding (< 1px) and padding on each side.
        final maxWidth = constraints.maxWidth;
        for (var i = 0;
            i < 3 && maxWidth.isFinite && maxWidth > 8 && layout.totalWidth > maxWidth;
            i++) {
          size *= (maxWidth - 2 * (1 + _sidePadding)) / layout.contentWidth;
          layout = _measure(parts, size, textScaler);
        }

        final baseStyle = _baseStyle(size);
        final orpStyle = _orpStyle(size);

        // Both sides get the same width, so the ORP character is always
        // exactly in the middle of the row (and of the screen).
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Before ORP - right aligned against the ORP character
            SizedBox(
              width: layout.sideWidth,
              child: Text(
                parts.before,
                style: baseStyle,
                textAlign: TextAlign.right,
                maxLines: 1,
              ),
            ),

            // ORP character - the center point
            Text(
              parts.orp,
              style: orpStyle,
              maxLines: 1,
            ),

            // After ORP - left aligned against the ORP character
            SizedBox(
              width: layout.sideWidth,
              child: Text(
                parts.after,
                style: baseStyle,
                textAlign: TextAlign.left,
                maxLines: 1,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Extra space added to each side so rounding never forces a line break
  static const double _sidePadding = 1;

  TextStyle _baseStyle(double size) => _getTextStyle(
        fontSize: size,
        color: textColor,
        fontWeight: fontWeight,
      );

  TextStyle _orpStyle(double size) => _getTextStyle(
        fontSize: size,
        color: showHighlight ? orpColor : textColor,
        fontWeight: showHighlight ? orpFontWeight : fontWeight,
      );

  /// Measure the rendered widths of the three word parts at [size]
  _ORPLayout _measure(ORPWordParts parts, double size, TextScaler textScaler) {
    final baseStyle = _baseStyle(size);

    final before = _textWidth(parts.before, baseStyle, textScaler);
    final orp = _textWidth(parts.orp, _orpStyle(size), textScaler);
    final after = _textWidth(parts.after, baseStyle, textScaler);

    final longestSide = before > after ? before : after;
    return _ORPLayout(
      sideWidth: longestSide.ceilToDouble() + _sidePadding,
      orpWidth: orp,
      contentWidth: longestSide * 2 + orp,
    );
  }

  double _textWidth(String text, TextStyle style, TextScaler textScaler) {
    if (text.isEmpty) return 0;

    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
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
}

/// Measured widths used to lay out a word around its ORP character
class _ORPLayout {
  /// Width given to both the before and after parts
  final double sideWidth;

  /// Width of the ORP character
  final double orpWidth;

  /// Width of the word content without rounding/padding
  final double contentWidth;

  const _ORPLayout({
    required this.sideWidth,
    required this.orpWidth,
    required this.contentWidth,
  });

  /// Total width of the laid out row
  double get totalWidth => sideWidth * 2 + orpWidth;
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
