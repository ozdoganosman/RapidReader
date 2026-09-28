import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/utils/text_parser.dart';
import 'package:rapid_reader/core/utils/timing_calculator.dart';

List<String> _words(String text, {int chunkSize = 1}) =>
    TextParser.parse(text, chunkSize: chunkSize).map((t) => t.word).toList();

void main() {
  group('TextParser keeps words intact', () {
    test('splits by whitespace only', () {
      expect(_words("Türkiye'nin e-posta ve/veya https://example.com/a"), [
        "Türkiye'nin",
        'e-posta',
        've/veya',
        'https://example.com/a',
      ]);
    });

    test('quotes and brackets stay attached', () {
      expect(_words('"Merhaba" dedi (sessizce).'), ['"Merhaba"', 'dedi', '(sessizce).']);
    });
  });

  group('TextParser attaches standalone punctuation', () {
    test('quotes surrounded by spaces', () {
      expect(_words('" Merhaba " dedi.'), ['"Merhaba"', 'dedi.']);
      expect(_words('“ Evet ” dedi.'), ['“Evet”', 'dedi.']);
    });

    test('closing punctuation goes to the previous word', () {
      expect(_words('Nasılsın ? Ben de ...'), ['Nasılsın?', 'Ben', 'de...']);
    });

    test('dashes keep their space', () {
      expect(_words('bir — iki'), ['bir —', 'iki']);
      expect(_words('— Merhaba, dedi.'), ['— Merhaba,', 'dedi.']);
    });
  });

  group('TextParser token flags', () {
    test('each line ends a paragraph', () {
      final tokens = TextParser.parse('İki Şehrin Hikayesi\nCharles Dickens\n\nEn iyi zamanlardı.');
      expect(
        tokens.where((t) => t.isParagraphEnd).map((t) => t.word),
        ['Hikayesi', 'Dickens', 'zamanlardı.'],
      );
    });

    test('sentence end is found before a closing quote', () {
      final tokens = TextParser.parse('"Geldim." dedi. Sonra gitti');
      expect(tokens.map((t) => t.hasSentenceEndPunctuation), [true, true, false, false]);
    });

    test('mid-sentence punctuation before a closing bracket', () {
      expect(TextParser.parse('(sessizce), dedi').first.hasMidSentencePunctuation, isTrue);
    });

    test('stats count words and paragraphs', () {
      final stats = TextParser.getStats(TextParser.parse('" Merhaba " dedi.\nTamam .'));
      expect(stats.wordCount, 3);
      expect(stats.paragraphCount, 2);
    });
  });

  group('TextParser chunking', () {
    test('groups words up to the chunk size', () {
      expect(_words('bir iki üç dört beş', chunkSize: 2), ['bir iki', 'üç dört', 'beş']);
    });

    test('chunks end at sentence and paragraph boundaries', () {
      expect(
        _words('Bir iki. Üç dört beş altı\nYedi sekiz', chunkSize: 3),
        ['Bir iki.', 'Üç dört beş', 'altı', 'Yedi sekiz'],
      );
    });

    test('keeps sentence and paragraph flags on the chunk', () {
      final tokens = TextParser.parse('Bir iki. Üç\nDört', chunkSize: 3);
      expect(tokens.map((t) => t.hasSentenceEndPunctuation), [true, false, false]);
      expect(tokens.map((t) => t.isParagraphEnd), [false, true, true]);
      expect(tokens.map((t) => t.index), [0, 1, 2]);
    });
  });

  group('TextParser abbreviations and ordinals', () {
    List<bool> ends(String text) => TextParser.parse(text).map((t) => t.hasSentenceEndPunctuation).toList();

    test('an ordinal or abbreviation before a lowercase word is no sentence end', () {
      expect(ends('19. yüzyılda geldi.'), [false, false, true]);
      expect(ends('elma, armut vb. meyveler'), [false, false, false, false]);
    });

    test('titles before a name are no sentence end', () {
      expect(ends('Dr. Ahmet geldi.'), [false, false, true]);
      expect(ends('St. Honoré sokağı'), [false, false, false]);
    });

    test('a period before a capital letter still ends the sentence', () {
      expect(ends('Geldi. Sonra gitti.'), [true, false, true]);
      expect(ends('1919. Sonra'), [true, false]);
      expect(ends('bekledi... ve gitti'), [true, false, false]); // ellipsis keeps its pause
    });

    test('word groups do not break at an ordinal', () {
      expect(_words('19. yüzyılda bir kent', chunkSize: 3), ['19. yüzyılda bir', 'kent']);
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
