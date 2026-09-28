/// PDF Text Extractor Service
///
/// Extracts text content from PDF files using Syncfusion PDF library.
/// Works on both web and mobile platforms using bytes.
library;

import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Service for extracting text from PDF documents
class PdfExtractor {
  /// Extract all text content from a PDF document
  ///
  /// [bytes] - PDF file as bytes (works on web and mobile)
  /// Returns extracted text as a single string. Pure Dart, so it can run
  /// in a background isolate via `compute`.
  static String extractText(Uint8List bytes) {
    final document = PdfDocument(inputBytes: bytes);

    try {
      final extractor = PdfTextExtractor(document);
      final buffer = StringBuffer();

      // Extract text from each page
      for (int i = 0; i < document.pages.count; i++) {
        final pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);
        if (pageText.isNotEmpty) {
          buffer.writeln(pageText);
          // Add paragraph break between pages
          buffer.writeln();
        }
      }

      return joinHyphenatedLineBreaks(buffer.toString().trim());
    } finally {
      document.dispose();
    }
  }

  /// Words hyphenated at a line break: "oku-" + newline + "ma"
  static final _hyphenatedLineBreak = RegExp(
    r'(\p{L})[-\u00AD][ \t]*\r?\n[ \t]*(\p{Ll})',
    unicode: true,
  );

  /// Join words that the PDF layout hyphenated at the end of a line
  ///
  /// "oku-\nma" becomes "okuma". Only joined when the next line continues
  /// with a lowercase letter, so "Doğu-\nBatı" and dashes before a new
  /// sentence or list item are kept. Remaining soft hyphens are removed.
  @visibleForTesting
  static String joinHyphenatedLineBreaks(String text) {
    return text
        .replaceAllMapped(_hyphenatedLineBreak, (m) => '${m[1]}${m[2]}')
        .replaceAll('\u00AD', '');
  }
}
