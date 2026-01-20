/// EPUB Text Extractor Service
///
/// Extracts text content from EPUB files using epubx library.
/// Works on both web and mobile platforms using bytes.
library;

import 'dart:typed_data';

import 'package:epubx/epubx.dart';

/// Service for extracting text from EPUB documents
class EpubExtractor {
  /// Extract all text content from an EPUB document
  ///
  /// [bytes] - EPUB file as bytes (works on web and mobile)
  /// Returns extracted text as a single string
  static Future<String> extractText(Uint8List bytes) async {
    final book = await EpubReader.readBook(bytes);
    final buffer = StringBuffer();

    // Get book title if available
    if (book.Title != null && book.Title!.isNotEmpty) {
      buffer.writeln(book.Title);
      buffer.writeln();
    }

    // Extract text from chapters
    if (book.Chapters != null) {
      for (final chapter in book.Chapters!) {
        _extractChapterText(chapter, buffer);
      }
    }

    // If no chapters, try to extract from content
    if (buffer.isEmpty && book.Content != null) {
      final html = book.Content!.Html;
      if (html != null) {
        for (final entry in html.entries) {
          final text = _stripHtml(entry.value.Content ?? '');
          if (text.isNotEmpty) {
            buffer.writeln(text);
            buffer.writeln();
          }
        }
      }
    }

    return buffer.toString().trim();
  }

  /// Recursively extract text from a chapter and its subchapters
  static void _extractChapterText(EpubChapter chapter, StringBuffer buffer) {
    // Add chapter title
    if (chapter.Title != null && chapter.Title!.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(chapter.Title);
      buffer.writeln();
    }

    // Add chapter content
    if (chapter.HtmlContent != null && chapter.HtmlContent!.isNotEmpty) {
      final text = _stripHtml(chapter.HtmlContent!);
      if (text.isNotEmpty) {
        buffer.writeln(text);
      }
    }

    // Process subchapters
    if (chapter.SubChapters != null) {
      for (final subChapter in chapter.SubChapters!) {
        _extractChapterText(subChapter, buffer);
      }
    }
  }

  /// Remove HTML tags and decode entities
  static String _stripHtml(String html) {
    // Remove script and style tags with their content
    var result = html.replaceAll(
      RegExp(r'<(script|style)[^>]*>.*?</\1>', caseSensitive: false, dotAll: true),
      '',
    );

    // Remove all HTML tags
    result = result.replaceAll(RegExp(r'<[^>]+>'), ' ');

    // Decode common HTML entities
    result = _decodeHtmlEntities(result);

    // Normalize whitespace
    result = result.replaceAll(RegExp(r'\s+'), ' ');

    // Split into lines and trim each
    final lines = result.split(RegExp(r'\n+'));
    final cleanedLines = lines.map((line) => line.trim()).where((line) => line.isNotEmpty);

    return cleanedLines.join('\n');
  }

  /// Decode HTML entities to regular characters
  static String _decodeHtmlEntities(String text) {
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
        .replaceAll('&lsquo;', ''')
        .replaceAll('&rsquo;', ''')
        .replaceAll('&ldquo;', '"')
        .replaceAll('&rdquo;', '"')
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

  /// Get metadata from EPUB
  static Future<EpubMetadata> getMetadata(Uint8List bytes) async {
    final book = await EpubReader.readBook(bytes);

    return EpubMetadata(
      title: book.Title ?? 'Bilinmeyen',
      author: book.Author ?? 'Bilinmeyen Yazar',
      chapterCount: book.Chapters?.length ?? 0,
    );
  }
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
