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

  /// Decode HTML entities to regular characters
  @visibleForTesting
  static String decodeHtmlEntities(String text) {
    return text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll('&hellip;', '...')
        .replaceAll('&lsquo;', '\u2018')
        .replaceAll('&rsquo;', '\u2019')
        .replaceAll('&ldquo;', '\u201C')
        .replaceAll('&rdquo;', '\u201D')
        .replaceAll('&bull;', '•')
        .replaceAll('&copy;', '©')
        .replaceAll('&reg;', '®')
        .replaceAll('&trade;', '™')
        // Turkish characters
        .replaceAll('&#305;', 'ı')
        .replaceAll('&#287;', 'ğ')
        .replaceAll('&#252;', 'ü')
        .replaceAll('&#351;', 'ş')
        .replaceAll('&#246;', 'ö')
        .replaceAll('&#231;', 'ç')
        .replaceAll('&#304;', 'İ')
        .replaceAll('&#286;', 'Ğ')
        .replaceAll('&#220;', 'Ü')
        .replaceAll('&#350;', 'Ş')
        .replaceAll('&#214;', 'Ö')
        .replaceAll('&#199;', 'Ç')
        // Numeric entities
        .replaceAllMapped(
          RegExp(r'&#(\d+);'),
          (match) {
            final code = int.tryParse(match.group(1) ?? '');
            if (code != null && code > 0 && code < 65536) {
              return String.fromCharCode(code);
            }
            return match.group(0) ?? '';
          },
        )
        // Hex entities
        .replaceAllMapped(
          RegExp(r'&#x([0-9a-fA-F]+);'),
          (match) {
            final code = int.tryParse(match.group(1) ?? '', radix: 16);
            if (code != null && code > 0 && code < 65536) {
              return String.fromCharCode(code);
            }
            return match.group(0) ?? '';
          },
        );
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
