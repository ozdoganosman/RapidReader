import 'dart:convert';
import 'dart:ui';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/services/document_importer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

Future<Uint8List> _buildPdf(String text) async {
  final document = PdfDocument();
  document.pages.add().graphics.drawString(
        text,
        PdfStandardFont(PdfFontFamily.helvetica, 12),
        bounds: const Rect.fromLTWH(0, 0, 500, 100),
      );
  final bytes = Uint8List.fromList(await document.save());
  document.dispose();
  return bytes;
}

/// Minimal EPUB 2 file with one chapter
Uint8List _buildEpub({required String title, required String author}) {
  final archive = Archive();
  void add(String name, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  add('mimetype', 'application/epub+zip');
  add('META-INF/container.xml', '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/></rootfiles>
</container>''');
  add('OEBPS/content.opf', '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="id" version="2.0">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>$title</dc:title>
    <dc:creator>$author</dc:creator>
    <dc:identifier id="id">test-1</dc:identifier>
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="ch1" href="ch1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine toc="ncx"><itemref idref="ch1"/></spine>
</package>''');
  add('OEBPS/toc.ncx', '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head><meta name="dtb:uid" content="test-1"/></head>
  <docTitle><text>$title</text></docTitle>
  <navMap>
    <navPoint id="n1" playOrder="1">
      <navLabel><text>Birinci Bölüm</text></navLabel><content src="ch1.xhtml"/>
    </navPoint>
  </navMap>
</ncx>''');
  add('OEBPS/ch1.xhtml', '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Bölüm</title></head>
<body><p>Bir zamanlar bir kitap varmış.</p></body>
</html>''');

  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

void main() {
  test('reads a Windows-1254 TXT file and names it after the file', () async {
    // "Işık ğüşöç" encoded as Windows-1254
    final bytes = Uint8List.fromList([0x49, 0xFE, 0xFD, 0x6B, 0x20, 0xF0, 0xFC, 0xFE, 0xF6, 0xE7]);

    final document = await DocumentImporter.read('Notlarım.TXT', bytes);

    expect(document.title, 'Notlarım');
    expect(document.author, isNull);
    expect(document.content, 'Işık ğüşöç');
  });

  test('reads the text of a PDF file', () async {
    final document = await DocumentImporter.read('rapor.pdf', await _buildPdf('PDF metni burada.'));

    expect(document.title, 'rapor');
    expect(document.content, contains('PDF metni burada.'));
  });

  test('uses the EPUB title and author', () async {
    final bytes = _buildEpub(title: 'Deneme Kitabı', author: 'Yazar Adı');

    final document = await DocumentImporter.read('dosya.epub', bytes);

    expect(document.title, 'Deneme Kitabı');
    expect(document.author, 'Yazar Adı');
    expect(document.content, contains('Bir zamanlar bir kitap varmış.'));
  });

  test('falls back to the file name when the EPUB has no metadata', () async {
    final document = await DocumentImporter.read('dosya.epub', _buildEpub(title: '', author: ''));

    expect(document.title, 'dosya');
    expect(document.author, isNull);
  });

  test('rejects unsupported files and files without text', () async {
    await expectLater(
      DocumentImporter.read('resim.png', Uint8List.fromList([1, 2, 3])),
      throwsA(isA<DocumentImportException>()),
    );
    await expectLater(
      DocumentImporter.read('bos.txt', Uint8List.fromList(utf8.encode('  \n\n '))),
      throwsA(isA<DocumentImportException>().having(
        (e) => e.message,
        'message',
        'Dosyada okunabilir metin bulunamadı',
      )),
    );
  });
}
