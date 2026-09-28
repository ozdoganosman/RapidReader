/// ORP Text Widget
///
/// Displays a word with the Optimal Recognition Point highlighted.
/// The ORP character is centered on screen and highlighted in a different color.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/data/quran.dart';

import '../../core/utils/orp_calculator.dart';

/// Widget that displays a word with ORP highlighting
///
/// The word is split into three parts:
/// - Before ORP: normal style, right-aligned
/// - ORP character: highlighted (colored/bold), exactly in the middle
/// - After ORP: normal style, left-aligned
///
/// The parts are measured with their real rendered widths (not a fixed
/// character width), so no characters are clipped with any font.
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

    // Right-to-left words (Arabic surah names in the first line of each
    // surah) are shown whole: split into three left-to-right parts their
    // pieces would be reversed and their letters unjoined
    if (_rightToLeft.hasMatch(word)) return _buildWhole();

    final parts = ORPCalculator.splitForDisplay(word);
    final textScaler = MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling;
    // The parts are drawn with the inherited text style merged in (the
    // theme's letter spacing, for one), so they are measured with it too
    final inherited = DefaultTextStyle.of(context).style;

    // Measure again once a font has loaded (the first word is often shown
    // before the reading font is ready; its old widths would clip it)
    return ListenableBuilder(
      listenable: PaintingBinding.instance.systemFonts,
      builder: (context, _) => LayoutBuilder(
        builder: (context, constraints) {
          var size = fontSize;
          var layout = _measure(parts, size, textScaler, inherited);

          // Shrink long words (or chunks) so they fit instead of wrapping.
          // Leave room for the rounding (< 1px) and padding on each side.
          final maxWidth = constraints.maxWidth;
          for (var i = 0; i < 3 && maxWidth.isFinite && maxWidth > 8 && layout.totalWidth > maxWidth; i++) {
            size *= (maxWidth - 2 * (1 + _sidePadding)) / layout.contentWidth;
            layout = _measure(parts, size, textScaler, inherited);
          }

          final baseStyle = _baseStyle(size);
          final orpStyle = _orpStyle(size);

          // Both sides get the same width, so the ORP character is always
          // exactly in the middle of the row (and on the focus guides).
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
                  softWrap: false,
                ),
              ),

              // ORP character - the center point
              Text(
                parts.orp,
                style: orpStyle,
                maxLines: 1,
                softWrap: false,
              ),

              // After ORP - left aligned against the ORP character
              SizedBox(
                width: layout.sideWidth,
                child: Text(
                  parts.after,
                  style: baseStyle,
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            ],
          );
        },
      ),
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
  _ORPLayout _measure(ORPWordParts parts, double size, TextScaler textScaler, TextStyle inherited) {
    final baseStyle = inherited.merge(_baseStyle(size));

    final before = _textWidth(parts.before, baseStyle, textScaler);
    final orp = _textWidth(parts.orp, inherited.merge(_orpStyle(size)), textScaler);
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

  /// Right-to-left scripts (Hebrew, Arabic)
  static final _rightToLeft = RegExp('[\u0590-\u08FF\uFB1D-\uFDFF\uFE70-\uFEFF]');

  /// A right-to-left word, whole and centered, shrunk to fit; it falls back
  /// to the bundled Arabic font
  Widget _buildWhole() {
    final style = _getTextStyle(fontSize: fontSize, color: textColor, fontWeight: fontWeight);
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        word,
        style: style.copyWith(fontFamilyFallback: [...?style.fontFamilyFallback, quranArabicFont]),
        maxLines: 1,
        softWrap: false,
      ),
    );
  }

  TextStyle _getTextStyle({
    required double fontSize,
    required Color color,
    required FontWeight fontWeight,
  }) =>
      readingFontStyle(fontFamily, fontSize: fontSize, color: color, fontWeight: fontWeight);

  /// The style of the reading font [fontFamily] (also used for the font
  /// previews in the settings)
  static TextStyle readingFontStyle(
    String fontFamily, {
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    // Use Google Fonts for proper web support with Turkish characters
    switch (fontFamily) {
      case 'OpenDyslexic':
        // Bundled font (not a Google Font)
        return TextStyle(
          fontFamily: 'OpenDyslexic',
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          height: 1.2,
        );
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
    final guideColor = focusGuideColor ?? orpColor.withValues(alpha: 0.5);

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
