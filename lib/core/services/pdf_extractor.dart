/// PDF Text Extractor Service
///
/// Extracts text content from PDF files using Syncfusion PDF library.
/// Works on both web and mobile platforms using bytes.
library;

import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

/// Service for extracting text from PDF documents
class PdfExtractor {
  /// Extract all text content from a PDF document
  ///
  /// [bytes] - PDF file as bytes (works on web and mobile)
  /// Returns extracted text as a single string
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

      return buffer.toString().trim();
    } finally {
      document.dispose();
    }
  }

  /// Extract text from specific page range
  ///
  /// [bytes] - PDF file as bytes
  /// [startPage] - Starting page index (0-based)
  /// [endPage] - Ending page index (inclusive)
  static String extractTextFromPages(
    Uint8List bytes, {
    required int startPage,
    required int endPage,
  }) {
    final document = PdfDocument(inputBytes: bytes);

    try {
      final extractor = PdfTextExtractor(document);
      final maxPage = document.pages.count - 1;

      // Clamp page indices
      final start = startPage.clamp(0, maxPage);
      final end = endPage.clamp(0, maxPage);

      return extractor.extractText(startPageIndex: start, endPageIndex: end);
    } finally {
      document.dispose();
    }
  }

  /// Get the number of pages in a PDF document
  static int getPageCount(Uint8List bytes) {
    final document = PdfDocument(inputBytes: bytes);
    try {
      return document.pages.count;
    } finally {
      document.dispose();
    }
  }
}
