import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/services/pdf_extractor.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

Future<Uint8List> _buildPdf(List<String> pages) async {
  final document = PdfDocument();
  final font = PdfStandardFont(PdfFontFamily.helvetica, 12);
  for (final text in pages) {
    document.pages.add().graphics.drawString(text, font, bounds: const Rect.fromLTWH(0, 0, 500, 100));
  }
  final bytes = Uint8List.fromList(await document.save());
  document.dispose();
  return bytes;
}

void main() {
  test('extracts text in a background isolate', () async {
    final bytes = await _buildPdf(['First page text.', 'Second page text.']);

    final text = await compute(PdfExtractor.extractText, bytes);

    expect(text, contains('First page text.'));
    expect(text, contains('Second page text.'));
  });

  group('PdfExtractor.joinHyphenatedLineBreaks', () {
    test('joins words split across lines', () {
      expect(PdfExtractor.joinHyphenatedLineBreaks('Kitap oku-\nmayı sever.'), 'Kitap okumayı sever.');
      expect(PdfExtractor.joinHyphenatedLineBreaks('ağır bir bas-  \n  kı altında'), 'ağır bir baskı altında');
      expect(PdfExtractor.joinHyphenatedLineBreaks('ka-\r\nlem'), 'kalem');
    });

    test('removes soft hyphens', () {
      expect(PdfExtractor.joinHyphenatedLineBreaks('oku\u00AD\nma ve ya\u00ADzı'), 'okuma ve yazı');
    });

    test('keeps dashes that are not line-break hyphenation', () {
      for (final text in [
        'Doğu-\nBatı ilişkileri', // next line starts uppercase
        'bir kelime -\nbaşka', // dash after a space
        'son satır-\n\nyeni paragraf', // paragraph break
        'e-posta adresi', // no line break
      ]) {
        expect(PdfExtractor.joinHyphenatedLineBreaks(text), text);
      }
    });
  });
}
