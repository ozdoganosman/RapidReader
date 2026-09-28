import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rapid_reader/core/services/article_extractor.dart';

const _page = '''<!doctype html>
<html><head>
  <title>Site | Makale</title>
  <meta property="og:title" content="Kuşların Göç Yolları">
  <script>var x = 1;</script>
</head>
<body>
  <header><nav><a href="/">Ana sayfa</a> <a href="/haber">Haberler</a></nav></header>
  <aside><p>Reklam: bu hafta indirim var, hemen tıklayın.</p></aside>
  <article>
    <h1>Kuşların Göç Yolları</h1>
    <p>Her sonbaharda milyonlarca kuş, binlerce kilometrelik yolculuklara çıkar ve güneydeki sıcak bölgelere ulaşır.</p>
    <p>Göç eden kuşlar yönlerini bulmak için güneşi, yıldızları ve yeryüzünün manyetik alanını kullanır.</p>
    <ul><li>Leylekler Afrika'ya kadar uçar.</li></ul>
    <p>Türkiye, bu yolların önemli kavşaklarından biridir; özellikle Boğaziçi her yıl binlerce süzülen kuşa ev sahipliği yapar.</p>
  </article>
  <footer><p>Tüm hakları saklıdır. İletişim bilgileri.</p></footer>
</body></html>''';

void main() {
  test('keeps the title and the article paragraphs, drops menus, ads and footer', () {
    final article = ArticleExtractor.parse(_page);

    expect(article.title, 'Kuşların Göç Yolları');
    expect(article.text, contains('milyonlarca kuş'));
    expect(article.text, contains("Leylekler Afrika'ya kadar uçar."));
    expect(article.text, isNot(contains('Reklam')));
    expect(article.text, isNot(contains('Ana sayfa')));
    expect(article.text, isNot(contains('hakları saklıdır')));
    expect(article.text.split('\n\n').length, greaterThanOrEqualTo(4));
  });

  test('fetches a page and decodes a Windows-1254 Turkish page', () async {
    final client = MockClient((request) async {
      expect(request.url.toString(), 'https://ornek.com/yazi');
      // "Işık ve gölge üzerine uzun bir yazı." in Windows-1254 inside a paragraph
      final body = <int>[
        ...latin1.encode('<html><body><article><p>'),
        0x49,
        0xFE,
        0xFD,
        0x6B,
        ...latin1.encode(' ve g'),
        0xF6,
        0x6C,
        0x67,
        0x65,
        ...latin1.encode(' '),
        0xFC,
        0x7A,
        0x65,
        0x72,
        0x69,
        0x6E,
        0x65,
        ...latin1.encode(' uzun bir yaz'),
        0xFD,
        ...latin1.encode('.</p></article></body></html>'),
      ];
      return http.Response.bytes(body, 200);
    });

    final article = await ArticleExtractor.fetch('https://ornek.com/yazi', client: client);
    expect(article.text, 'Işık ve gölge üzerine uzun bir yazı.');
  });

  test('reports errors as messages', () async {
    final notFound = MockClient((_) async => http.Response('yok', 404));
    await expectLater(
        ArticleExtractor.fetch('https://ornek.com/x', client: notFound), throwsA(isA<ArticleException>()));
    await expectLater(ArticleExtractor.fetch('ornek', client: notFound), throwsA(isA<ArticleException>()));
  });

  test('recognises links and shared "title + link" texts', () {
    expect(ArticleExtractor.isUrl('https://ornek.com/a?b=1'), isTrue);
    expect(ArticleExtractor.isUrl('ornek.com'), isFalse);
    expect(ArticleExtractor.isUrl('iki kelime https://ornek.com'), isFalse);

    expect(ArticleExtractor.linkInSharedText('Güzel bir yazı https://ornek.com/yazi'), 'https://ornek.com/yazi');
    expect(ArticleExtractor.linkInSharedText('Bağlantı yok'), isNull);
    expect(ArticleExtractor.linkInSharedText('${'uzun metin ' * 30} https://ornek.com'), isNull);
  });

  test('a <br> separates words and lines', () {
    final article = ArticleExtractor.parse('<html><body><article>'
        '<p>İlk paragrafın sonu.<br><br>İkinci paragraf burada.</p>'
        '<p>bir<br/>şiir satırı</p>'
        '</article></body></html>');
    expect(article.text, 'İlk paragrafın sonu.\nİkinci paragraf burada.\n\nbir\nşiir satırı');
  });
}
