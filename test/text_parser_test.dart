import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/utils/text_parser.dart';
import 'package:rapid_reader/core/utils/timing_calculator.dart';

List<String> _words(String text, {int chunkSize = 1}) =>
    TextParser.parse(text, chunkSize: chunkSize).map((t) => t.word).toList();

void main() {
  group('TextParser keeps punctuation with words', () {
    test('quotes and brackets stay attached', () {
      expect(_words('"Merhaba" dedi (sessizce).'), ['"Merhaba"', 'dedi', '(sessizce).']);
      expect(_words('«Evet» dedi.'), ['«Evet»', 'dedi.']);
    });

    test('standalone quotes attach to the quoted words', () {
      expect(_words('" Merhaba " dedi.'), ['"Merhaba"', 'dedi.']);
      expect(_words('“ Evet ” dedi.'), ['“Evet”', 'dedi.']);
    });

    test('standalone closing punctuation attaches to the previous word', () {
      expect(_words('Nasılsın ? Ben de ...'), ['Nasılsın?', 'Ben', 'de...']);
    });

    test('dashes keep their space', () {
      expect(_words('bir — iki'), ['bir —', 'iki']);
      expect(_words('— Merhaba, dedi.'), ['— Merhaba,', 'dedi.']);
    });

    test('apostrophes and hyphens stay inside the word', () {
      expect(_words("Türkiye'nin e-posta adresi"), ["Türkiye'nin", 'e-posta', 'adresi']);
    });

    test('slashes split words', () {
      expect(_words('ve/veya (a/b)'), ['ve', 'veya', '(a', 'b)']);
    });

    test('URLs stay whole', () {
      expect(_words('Bkz. https://example.com/a/b adresi'), ['Bkz.', 'https://example.com/a/b', 'adresi']);
    });
  });

  group('TextParser token flags', () {
    test('sentence end is found before a closing quote', () {
      final tokens = TextParser.parse('"Geldim." dedi. Sonra gitti');
      expect(tokens.map((t) => t.hasSentenceEndPunctuation), [true, true, false, false]);
    });

    test('mid-sentence punctuation before a closing bracket', () {
      final tokens = TextParser.parse('(sessizce), dedi');
      expect(tokens.first.hasMidSentencePunctuation, isTrue);
    });

    test('paragraph ends are marked', () {
      final tokens = TextParser.parse('Bir iki.\n\nÜç dört.');
      expect(tokens.where((t) => t.isParagraphEnd).map((t) => t.word), ['iki.', 'dört.']);
    });

    test('word count does not include punctuation', () {
      final stats = TextParser.getStats(TextParser.parse('" Merhaba " dedi — tamam .'));
      expect(stats.wordCount, 3);
    });
  });

  group('TimingCalculator.detectPunctuation', () {
    test('looks past closing quotes and brackets', () {
      expect(TimingCalculator.detectPunctuation('dedi."'), PunctuationType.sentenceEnd);
      expect(TimingCalculator.detectPunctuation('(sessizce),'), PunctuationType.midSentence);
      expect(TimingCalculator.detectPunctuation('bekledi…”'), PunctuationType.ellipsis);
    });

    test('brackets without punctuation', () {
      expect(TimingCalculator.detectPunctuation('"Merhaba"'), PunctuationType.closingBracket);
      expect(TimingCalculator.detectPunctuation('(sessizce'), PunctuationType.openingBracket);
      expect(TimingCalculator.detectPunctuation('kelime'), PunctuationType.none);
    });

    test('attached dashes', () {
      expect(TimingCalculator.detectPunctuation('bir —'), PunctuationType.longDash);
    });
  });
}
