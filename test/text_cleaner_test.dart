import 'package:flutter_test/flutter_test.dart';
import 'package:rapid_reader/core/services/text_cleaner.dart';

void main() {
  group('TextCleaner.clean keeps prose intact', () {
    test('Turkish "baskı" inside a sentence is not removed', () {
      const text = 'Halk uzun yıllar ağır bir baskı altında yaşadı ve sonunda isyan etti.';
      expect(TextCleaner.clean(text), text);
    });

    test('"basımı" inside a sentence is not removed', () {
      const text = 'Kitabın ilk basımı 1950 yılında yapıldı. Hikaye burada başlıyor.';
      expect(TextCleaner.clean(text), text);
    });

    test('English "publishers" inside a sentence is not removed', () {
      const text = 'The publishers rejected the manuscript three times before it became famous.';
      expect(TextCleaner.clean(text), text);
    });

    test('inline ® and © symbols in prose are kept', () {
      const text = 'Coca-Cola® içtik ve © işaretini gördük, sonra yolumuza devam ettik.';
      expect(TextCleaner.clean(text), text);
    });

    test('long lines mentioning rights are treated as prose', () {
      final text = 'Yazar, tüm hakları saklıdır ibaresinin ne anlama geldiğini ${'uzun uzun ' * 10}anlattı.';
      expect(TextCleaner.clean(text), text);
    });
  });

  group('TextCleaner.clean removes metadata lines', () {
    const prose = 'Birinci paragraf burada.';

    for (final line in [
      '© 2020 Yapı Kredi Yayınları',
      '(c) 2019 John Doe',
      'Copyright © 2019 by John Doe',
      'Telif Hakkı © Can Yayınları',
      'Tüm hakları saklıdır.',
      'TÜM HAKLARI SAKLIDIR',
      'Her hakkı saklıdır.',
      'All rights reserved.',
      'ISBN 978-605-360-123-4',
      'ISBN: 9786053601234',
      'Published by Penguin Books',
      'First published in 1998',
      'Yayınevi: Can Yayınları',
      'YAYINEVİ: Can Yayınları',
      'Publisher: Penguin',
      '1. Baskı: Mart 2020',
      '1. Baskı, 2019',
      'BİRİNCİ BASKI, 2019',
      'Birinci Basım Mart 2020',
      'Basım: Ayhan Matbaası',
    ]) {
      test('removes "$line"', () {
        expect(TextCleaner.clean('$line\n$prose'), prose);
      });
    }
  });

  group('TextCleaner.clean removes page furniture', () {
    test('page numbers and page labels', () {
      const text = 'Birinci satır.\n12\nİkinci satır.\nSayfa 13\nPage 14\nÜçüncü satır.';
      expect(TextCleaner.clean(text), 'Birinci satır.\nİkinci satır.\nÜçüncü satır.');
    });

    test('standalone footnote markers', () {
      expect(TextCleaner.clean('Metin.\n[1]\n(2)\nDevam.'), 'Metin.\nDevam.');
    });

    test('inline ISBN numbers are stripped from longer lines', () {
      const text = 'Bu kitabın numarası ISBN 978-605-360-123-4 olarak kayıtlıdır ve raflarda bulunur, '
          'kütüphanede de aynı numara ile aranabilir.';
      expect(TextCleaner.clean(text), isNot(contains('978-605')));
      expect(TextCleaner.clean(text), contains('kütüphanede de aynı numara'));
    });

    test('collapses excessive blank lines', () {
      expect(TextCleaner.clean('A.\n\n\n\n\nB.'), 'A.\n\nB.');
    });
  });

  test('a list item "(c)" is not taken for a copyright line', () {
    const list = '(a) Başvuru yapılır.\n(b) Belge verilir.\n(c) Ücret yatırılır.';
    expect(TextCleaner.clean(list), list);
    expect(TextCleaner.clean('Metin.\n(c) 2020 Yayınevi\nDevam.'), 'Metin.\nDevam.');
  });

  group('TextCleaner.joinWrappedLines', () {
    // A paragraph wrapped at about 60 characters, a heading and a dialog
    const wrapped = 'BİRİNCİ BÖLÜM\n'
        'Gregor Samsa bir sabah huzursuz düşlerden uyandığında,\n'
        'kendini yatağında korkunç bir böceğe dönüşmüş buldu. Zırh\n'
        'gibi sert sırtının üstünde yatıyordu ve başını biraz\n'
        'kaldırınca kahverengi karnını gördü.\n'
        '— Ne oldu bana? diye düşündü. Bir düş değildi bu, hayır\n'
        'odası gerçekten de insan odasıydı, küçüktü ama gerçekti.';

    test('joins the lines of each paragraph', () {
      expect(TextCleaner.joinWrappedLines(wrapped).split('\n\n'), [
        'BİRİNCİ BÖLÜM',
        'Gregor Samsa bir sabah huzursuz düşlerden uyandığında, kendini yatağında korkunç bir böceğe '
            'dönüşmüş buldu. Zırh gibi sert sırtının üstünde yatıyordu ve başını biraz kaldırınca '
            'kahverengi karnını gördü.',
        '— Ne oldu bana? diye düşündü. Bir düş değildi bu, hayır odası gerçekten de insan odasıydı, '
            'küçüktü ama gerçekti.',
      ]);
    });

    test('an empty line always ends a paragraph', () {
      expect(TextCleaner.joinWrappedLines('Bir iki üç dört beş\naltı yedi\n\nsekiz dokuz on\nonbir'),
          'Bir iki üç dört beş altı yedi\n\nsekiz dokuz on onbir');
    });

    test('only if wrapped: one-line paragraphs and poems stay as they are', () {
      expect(TextCleaner.joinWrappedLines(wrapped, onlyIfWrapped: true), isNot(wrapped));
      const paragraphs = 'Kısa bir paragraf.\n'
          'Çok daha uzun bir paragraf; birkaç cümleden oluşuyor ve satır sonu olmadan yazılmış, '
          'çünkü dosyada her paragraf tek satır. Burada da devam ediyor ve bitiyor.\n'
          'Son.';
      expect(TextCleaner.joinWrappedLines(paragraphs, onlyIfWrapped: true), paragraphs);
      const poem = 'Ne içindeyim zamanın,\nNe büsbütün dışında;\nYekpare, geniş bir anın\nParçalanmaz akışında.';
      expect(TextCleaner.joinWrappedLines(poem, onlyIfWrapped: true), poem);
    });
  });
}
