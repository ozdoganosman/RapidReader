import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/services/epub_extractor.dart';

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
}
