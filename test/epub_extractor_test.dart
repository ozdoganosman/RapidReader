import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/services/epub_extractor.dart';
import 'package:rapid_reader/core/utils/text_parser.dart';

/// Build a minimal EPUB 2 file with a single XHTML file that the table of
/// contents references twice (chapter + sub-chapter anchor).
Uint8List _buildEpub(String chapterXhtml) {
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
    <dc:title>Deneme Kitabı</dc:title>
    <dc:creator>Yazar Adı</dc:creator>
    <dc:identifier id="id">test-1</dc:identifier>
    <dc:language>tr</dc:language>
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
  <docTitle><text>Deneme Kitabı</text></docTitle>
  <navMap>
    <navPoint id="n1" playOrder="1">
      <navLabel><text>Birinci Bölüm</text></navLabel><content src="ch1.xhtml"/>
      <navPoint id="n2" playOrder="2">
        <navLabel><text>Alt Bölüm</text></navLabel><content src="ch1.xhtml#s2"/>
      </navPoint>
    </navPoint>
  </navMap>
</ncx>''');
  add('OEBPS/ch1.xhtml', chapterXhtml);

  return Uint8List.fromList(ZipEncoder().encode(archive)!);
}

const _chapter = '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Sayfa Başlığı</title><style>p { margin: 0; }</style></head>
<body>
  <h1>Birinci Bölüm</h1>
  <p><span class="dropcap">B</span>ir zamanlar
     ağır bir baskı altında yaşayan bir halk varmış.</p>
  <p>Türkiye&#8217;nin en güzel şehri.</p>
  <h2 id="s2">Alt Bölüm</h2>
  <p>Son paragraf.</p>
</body>
</html>''';

void main() {
  group('EpubExtractor.decodeHtmlEntities', () {
    test('decodes curly single and double quotes', () {
      expect(
        EpubExtractor.decodeHtmlEntities('&lsquo;hi&rsquo; &ldquo;there&rdquo;'),
        '‘hi’ “there”',
      );
    });

    test('decodes a Turkish apostrophe written as &rsquo;', () {
      expect(
        EpubExtractor.decodeHtmlEntities('Türkiye&rsquo;nin'),
        'Türkiye’nin',
      );
    });

    test('decodes numeric and hex entities', () {
      expect(EpubExtractor.decodeHtmlEntities('&#305;&#x15F;'), 'ış');
    });
  });

  group('EpubExtractor.stripHtml', () {
    test('keeps paragraphs separated by a blank line', () {
      expect(
        EpubExtractor.stripHtml('<p>Birinci paragraf.</p>\n<p>İkinci paragraf.</p>'),
        'Birinci paragraf.\n\nİkinci paragraf.',
      );
    });

    test('treats source line breaks inside a paragraph as spaces', () {
      expect(EpubExtractor.stripHtml('<p>bir\n   iki</p>'), 'bir iki');
    });

    test('keeps <br> as a line break inside the paragraph', () {
      expect(EpubExtractor.stripHtml('<p>dize bir<br/>dize iki</p>'), 'dize bir\ndize iki');
    });

    test('does not split words at inline tags (drop caps)', () {
      expect(
        EpubExtractor.stripHtml('<p><span class="dropcap">B</span>ir <em>zamanlar</em></p>'),
        'Bir zamanlar',
      );
    });

    test('drops <head>, <script> and <style> content', () {
      expect(
        EpubExtractor.stripHtml(
          '<html><head><title>Başlık</title></head><body><script>x()</script><p>Metin</p></body></html>',
        ),
        'Metin',
      );
    });

    test('paragraph ends reach the RSVP tokens', () {
      final tokens = TextParser.parse(EpubExtractor.stripHtml('<p>Bir iki.</p><p>Üç dört.</p>'));
      expect(tokens.where((t) => t.isParagraphEnd).map((t) => t.word), ['iki.', 'dört.']);
    });
  });

  group('EpubExtractor.extract', () {
    late EpubDocument epub;
    late String text;

    setUpAll(() async {
      // Runs in a background isolate like in the app
      epub = await compute(EpubExtractor.extract, _buildEpub(_chapter));
      text = epub.text;
    });

    test('reads the metadata from the same parse', () {
      expect(epub.metadata.title, 'Deneme Kitabı');
      expect(epub.metadata.author, 'Yazar Adı');
    });

    test('extracts paragraphs with structure intact', () {
      expect(text, contains('Bir zamanlar ağır bir baskı altında yaşayan bir halk varmış.'));
      expect(text, contains('\n\nTürkiye’nin en güzel şehri.\n\n'));
      expect(text, contains('Son paragraf.'));
    });

    test('does not repeat a file referenced by a sub-chapter anchor', () {
      expect('Son paragraf.'.allMatches(text).length, 1);
      expect('Bir zamanlar'.allMatches(text).length, 1);
    });

    test('does not include the XHTML <title>', () {
      expect(text, isNot(contains('Sayfa Başlığı')));
    });
  });
}
