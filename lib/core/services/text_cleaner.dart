/// Text Cleaner Service
///
/// Cleans text extracted from PDFs and plain-text files by removing:
/// - Page numbers
/// - Copyright/ISBN/publisher lines
/// - Footnote marker lines
/// - Excessive whitespace
///
/// Only whole, short lines that look like metadata are removed. Words such as
/// "baskı" or "publishers" inside normal prose are never touched.
library;

/// Service for cleaning and preprocessing text before RSVP reading
class TextCleaner {
  /// Lines longer than this are treated as prose and never removed as metadata
  static const _maxMetadataLineLength = 100;

  // Whole-line noise patterns (matched against the trimmed line)
  static final _pageNumberPattern = RegExp(r'^\d{1,4}$');
  static final _pageLabelPattern = RegExp(
    r'^(?:page|sayfa|s\.)\s*\d+$',
    caseSensitive: false,
  );
  static final _footnotePattern = RegExp(r'^[\[\(]\d+[\]\)]$');

  // Inline ISBN numbers are always metadata, even inside a longer line
  static final _isbnPattern = RegExp(
    r'ISBN[\s\-:]*[\d\-X]{10,}',
    caseSensitive: false,
  );

  /// Metadata line patterns, matched against the folded (lowercase,
  /// dotless/dotted i normalized to "i") trimmed line.
  static final _metadataPatterns = [
    // © 2020 ..., (c) 2020 ..., Copyright ..., Telif hakkı ... (not a list
    // item "(c) ...")
    RegExp(r'^(?:©|\(c\)\s*(?:\d{4}|copyright\b)|copyright\b|telif hakk)'),
    // All rights reserved / Tüm hakları saklıdır / Her hakkı saklıdır
    RegExp(r'all rights reserved|(?:hakki|haklari) saklidir'),
    // ISBN 978-...
    RegExp(r'^isbn\b'),
    // Published by X / First published 1998 / First edition 2001
    RegExp(r'^(?:published by|first published|first edition)\b'),
    // Yayınevi: X / Publisher: X / 1. Baskı: Mart 2020 / Basım: X Matbaası
    RegExp(r'^(?:\d+\.\s*)?(?:publisher|yayinevi|yayinci|baski|basim)\s*:'),
    // 1. Baskı, 2019 / Birinci Baskı Mart 2020 / İlk Basım 2018
    RegExp(
      r'^(?:\d+\.\s*|birinci\s+|ilk\s+)?(?:baski|basim)\s*,?\s*(?:\S+\s+)?\d{4}\.?$',
    ),
  ];

  static final _excessiveNewlinesPattern = RegExp(r'\n\s*\n\s*\n+');
  static final _trailingWhitespacePattern = RegExp(r'[ \t]+$', multiLine: true);

  /// Main cleaning function - removes all common unwanted content
  static String clean(String text) {
    if (text.isEmpty) return text;

    final lines = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
    final kept = <String>[];

    for (final line in lines) {
      if (_isNoiseLine(line.trim())) continue;
      kept.add(line.replaceAll(_isbnPattern, ''));
    }

    return _normalizeWhitespace(kept.join('\n')).trim();
  }

  /// Whether a trimmed line is a page number, footnote marker or metadata
  static bool _isNoiseLine(String trimmed) {
    if (trimmed.isEmpty) return false;

    if (_pageNumberPattern.hasMatch(trimmed) ||
        _pageLabelPattern.hasMatch(trimmed) ||
        _footnotePattern.hasMatch(trimmed)) {
      return true;
    }

    // Long lines are prose, even if they mention "baskı" or "copyright"
    if (trimmed.length > _maxMetadataLineLength) return false;

    final folded = _fold(trimmed);
    return _metadataPatterns.any((p) => p.hasMatch(folded));
  }

  /// Join the lines of paragraphs that a fixed-width layout broke (PDF
  /// pages, hard-wrapped text files), so each paragraph is one line again:
  /// the reader pauses at every line end and reads a line as a paragraph.
  ///
  /// A line ends its paragraph when an empty line follows, when it is
  /// clearly shorter than the usual line (the last line of a paragraph, a
  /// heading) or ends a sentence while somewhat shorter, or when the next
  /// line starts a dialog line or list item. Paragraphs are separated by an
  /// empty line.
  ///
  /// With [onlyIfWrapped], text that does not look hard-wrapped (most
  /// lines of a similar length of 50-120 characters) is returned as it is,
  /// so one-line-per-paragraph texts and poems are kept.
  static String joinWrappedLines(String text, {bool onlyIfWrapped = false}) {
    final lines = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n');
    final lengths = [
      for (final line in lines)
        if (line.trim().isNotEmpty) line.trim().length
    ]..sort();
    if (lengths.length < 3) return text;

    // The usual length of a full line
    final typical = lengths[(lengths.length * 0.8).floor().clamp(0, lengths.length - 1)];
    if (onlyIfWrapped) {
      final full = lengths.where((length) => length >= typical * 0.7).length;
      if (typical < 50 || typical > 120 || full < lengths.length * 0.6) return text;
    }

    final paragraphs = <String>[];
    final current = <String>[];
    void flush() {
      if (current.isNotEmpty) paragraphs.add(current.join(' '));
      current.clear();
    }

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) {
        flush();
        continue;
      }
      current.add(line);

      final next = i + 1 < lines.length ? lines[i + 1].trim() : '';
      final endsParagraph = next.isEmpty ||
          line.length < typical * 0.6 ||
          (_endsSentence(line) && line.length < typical * 0.85) ||
          _startsBlock.hasMatch(next);
      if (endsParagraph) flush();
    }
    flush();
    return paragraphs.join('\n\n');
  }

  /// A sentence end (also before closing quotes or brackets) or a colon
  static final _sentenceEnd = RegExp('[.!?\u2026:][)\\]"\'\u00BB\u201D\u2019]*\$');

  static bool _endsSentence(String line) => _sentenceEnd.hasMatch(line);

  /// A dialog dash, bullet or numbered item at the start of a line
  static final _startsBlock = RegExp(r'^(?:[—–\-•*]\s|\d+[.)]\s)');

  /// Lowercase with Turkish I/İ/ı/i all folded to "i", so patterns match
  /// both "BASKI" and "baskı" as well as English words like "PUBLISHED".
  static String _fold(String text) {
    return text.replaceAll(RegExp('[Iİı]'), 'i').toLowerCase();
  }

  /// Normalize whitespace - reduce multiple blank lines to a single blank line
  static String _normalizeWhitespace(String text) {
    var result = text;

    // Remove trailing whitespace from lines
    result = result.replaceAll(_trailingWhitespacePattern, '');

    // Reduce 3+ consecutive newlines to 2
    result = result.replaceAll(_excessiveNewlinesPattern, '\n\n');

    return result;
  }
}
