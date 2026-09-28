/// EPUB Text Extractor Service
///
/// Extracts text content from EPUB files using epubx library.
/// Works on both web and mobile platforms using bytes.
library;

import 'dart:typed_data';

import 'package:epubx/epubx.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

/// Service for extracting text from EPUB documents
class EpubExtractor {
  /// Extract text and metadata from an EPUB document
  ///
  /// [bytes] - EPUB file as bytes (works on web and mobile)
  /// The file is parsed once for both. Pure Dart, so it can run in a
  /// background isolate via `compute`.
  static Future<EpubDocument> extract(Uint8List bytes) async {
    final book = await EpubReader.readBook(bytes);

    return EpubDocument(
      text: _extractText(book),
      metadata: EpubMetadata(
        title: book.Title ?? 'Bilinmeyen',
        author: book.Author ?? 'Bilinmeyen Yazar',
        chapterCount: book.Chapters?.length ?? 0,
      ),
    );
  }

  /// Extract all text content from a parsed book as a single string
  static String _extractText(EpubBook book) {
    final buffer = StringBuffer();

    // Get book title if available
    if (book.Title != null && book.Title!.isNotEmpty) {
      buffer.writeln(book.Title);
      buffer.writeln();
    }

    // Extract text from chapters
    final chapterBuffer = StringBuffer();
    if (book.Chapters != null) {
      final seenFiles = <String>{};
      for (final chapter in book.Chapters!) {
        _extractChapterText(chapter, chapterBuffer, seenFiles);
      }
    }

    // If no chapters, try to extract from content
    if (chapterBuffer.toString().trim().isEmpty && book.Content != null) {
      final html = book.Content!.Html;
      if (html != null) {
        for (final entry in html.entries) {
          final text = stripHtml(entry.value.Content ?? '');
          if (text.isNotEmpty) {
            chapterBuffer.writeln(text);
            chapterBuffer.writeln();
          }
        }
      }
    }

    buffer.write(chapterBuffer);
    return buffer.toString().trim();
  }

  /// Recursively extract text from a chapter and its subchapters
  static void _extractChapterText(
    EpubChapter chapter,
    StringBuffer buffer,
    Set<String> seenFiles,
  ) {
    // Sub-chapters that point to an anchor inside an already extracted file
    // carry the whole file again as HtmlContent; skip them to avoid duplicates
    final fileName = chapter.ContentFileName;
    final isNewFile = fileName == null || seenFiles.add(fileName);

    if (isNewFile) {
      // Add chapter title
      if (chapter.Title != null && chapter.Title!.isNotEmpty) {
        buffer.writeln();
        buffer.writeln(chapter.Title);
        buffer.writeln();
      }

      // Add chapter content
      if (chapter.HtmlContent != null && chapter.HtmlContent!.isNotEmpty) {
        final text = stripHtml(chapter.HtmlContent!);
        if (text.isNotEmpty) {
          buffer.writeln(text);
          buffer.writeln();
        }
      }
    }

    // Process subchapters
    if (chapter.SubChapters != null) {
      for (final subChapter in chapter.SubChapters!) {
        _extractChapterText(subChapter, buffer, seenFiles);
      }
    }
  }

  /// Convert XHTML to plain text, keeping paragraph structure
  ///
  /// Block elements (p, div, h1-h6, li, ...) become paragraph breaks (blank
  /// line), `<br>` becomes a line break, inline tags are removed without
  /// adding spaces and entities are decoded.
  @visibleForTesting
  static String stripHtml(String html) {
    // Drop <head> (holds <title>) and script/style blocks with their content
    var result = html.replaceAll(
      RegExp(r'<(head|script|style)\b[^>]*>.*?</\1\s*>', caseSensitive: false, dotAll: true),
      '',
    );

    // Line breaks in the source are ordinary whitespace in HTML
    result = result.replaceAll(RegExp(r'\s+'), ' ');

    // Block-level elements separate paragraphs, <br> breaks a line
    result = result.replaceAll(
      RegExp(
        r'</?(?:p|div|h[1-6]|li|ul|ol|dl|dt|dd|blockquote|section|article|aside|header|footer|figure|figcaption|table|tr|pre|hr|body)\b[^>]*>',
        caseSensitive: false,
      ),
      '\n\n',
    );
    result = result.replaceAll(RegExp(r'<br\b[^>]*>', caseSensitive: false), '\n');
    result = result.replaceAll(RegExp(r'</?(?:td|th)\b[^>]*>', caseSensitive: false), ' ');

    // Remove remaining (inline) tags without adding spaces, so drop caps
    // like <span>B</span>ir stay a single word
    result = result.replaceAll(RegExp(r'<[^>]*>'), '');

    // Decode common HTML entities
    result = decodeHtmlEntities(result);

    // Tidy up: trim lines, drop empty lines and paragraphs
    final paragraphs = <String>[];
    for (final paragraph in result.split(RegExp(r'\n[ \t]*\n'))) {
      final lines = paragraph
          .split('\n')
          .map((line) => line.replaceAll(RegExp(r'[ \t\u00A0]+'), ' ').trim())
          .where((line) => line.isNotEmpty);
      if (lines.isNotEmpty) paragraphs.add(lines.join('\n'));
    }

    return paragraphs.join('\n\n');
  }

  /// Named, decimal (&#305;) and hex (&#x131;) character references
  static final _entityPattern = RegExp(r'&(#[0-9]+|#[xX][0-9a-fA-F]+|[a-zA-Z][a-zA-Z0-9]*);');

  /// Named entities common in EPUB files, including Turkish letters
  static const _namedEntities = {
    'nbsp': ' ',
    'amp': '&',
    'lt': '<',
    'gt': '>',
    'quot': '"',
    'apos': "'",
    'mdash': '\u2014',
    'ndash': '\u2013',
    'hellip': '...',
    'lsquo': '\u2018',
    'rsquo': '\u2019',
    'sbquo': '\u201A',
    'ldquo': '\u201C',
    'rdquo': '\u201D',
    'bdquo': '\u201E',
    'laquo': '\u00AB',
    'raquo': '\u00BB',
    'bull': '\u2022',
    'middot': '\u00B7',
    'copy': '\u00A9',
    'reg': '\u00AE',
    'trade': '\u2122',
    'deg': '\u00B0',
    'shy': '', // soft hyphen
    'zwnj': '',
    'zwj': '',
    'ensp': ' ',
    'emsp': ' ',
    'thinsp': ' ',
    // Turkish letters
    'ccedil': 'ç',
    'Ccedil': 'Ç',
    'ouml': 'ö',
    'Ouml': 'Ö',
    'uuml': 'ü',
    'Uuml': 'Ü',
    'gbreve': 'ğ',
    'Gbreve': 'Ğ',
    'scedil': 'ş',
    'Scedil': 'Ş',
    'imath': 'ı',
    'inodot': 'ı',
    'Idot': 'İ',
    'acirc': 'â',
    'Acirc': 'Â',
    'icirc': 'î',
    'Icirc': 'Î',
    'ucirc': 'û',
    'Ucirc': 'Û',
    'eacute': 'é',
    'Eacute': 'É',
  };

  /// Decode HTML entities to regular characters
  ///
  /// Every reference is decoded exactly once, so "&amp;lt;" becomes the
  /// text "&lt;" rather than "<". Unknown entities are left as they are.
  @visibleForTesting
  static String decodeHtmlEntities(String text) {
    return text.replaceAllMapped(_entityPattern, (match) {
      final entity = match.group(1)!;

      if (entity.startsWith('#')) {
        final isHex = entity.length > 1 && (entity[1] == 'x' || entity[1] == 'X');
        final code = isHex ? int.tryParse(entity.substring(2), radix: 16) : int.tryParse(entity.substring(1));
        final isValid = code != null &&
            code > 0 &&
            code <= 0x10FFFF &&
            (code < 0xD800 || code > 0xDFFF); // not a lone surrogate
        return isValid ? String.fromCharCode(code) : match.group(0)!;
      }

      return _namedEntities[entity] ?? match.group(0)!;
    });
  }
}

/// Text and metadata extracted from an EPUB file
class EpubDocument {
  final String text;
  final EpubMetadata metadata;

  const EpubDocument({required this.text, required this.metadata});
}

/// EPUB metadata
class EpubMetadata {
  final String title;
  final String author;
  final int chapterCount;

  const EpubMetadata({
    required this.title,
    required this.author,
    required this.chapterCount,
  });
}
