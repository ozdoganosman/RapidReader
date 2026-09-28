# RapidReader

RSVP (Rapid Serial Visual Presentation) yöntemiyle hızlı okuma uygulaması.
Metin, kelime kelime ekranın ortasında gösterilir. Her kelimenin odak harfi
(ORP, Optimal Recognition Point) vurgulanır ve hep aynı noktada durur;
böylece göz satır boyunca hareket etmek zorunda kalmaz.

Flutter ile yazılmıştır; Android ve web üzerinde çalışır.

## Özellikler

- **Dosya içe aktarma:** TXT, PDF ve EPUB
  - TXT: UTF-8 (BOM'lu/BOM'suz), UTF-16 ve Windows-1254 (Türkçe ANSI) otomatik algılanır
  - PDF: sayfa numaraları, ISBN/telif satırları temizlenir; satır sonunda bölünmüş kelimeler birleştirilir
  - EPUB: paragraf yapısı korunur, HTML karakter referansları çözülür
- **Metin yapıştırma** ve örnek Türkçe metin
- **Uyarlanabilir hız:** kısa kelimeler hızlı, uzun kelimeler yavaş; noktalama ve paragraf sonlarında duraklama
- **Mikro-duraklama:** belirli sayıda cümlede bir kısa ara
- **Kelime gruplama (chunk):** 1–3 kelime birlikte; gruplar cümle ve paragraf sınırında biter
- **Türkçe desteği:** kesme işaretli kelimeler (Türkiye'nin) tek kelime kalır, odak harfi hiçbir zaman kesme işaretine/tireye düşmez
- **Kaldığın yerden devam:** ayarlar, okuma geçmişi ve konum cihazda saklanır (web'de IndexedDB)
- **Okuma ekranı:** dokun-oynat/duraklat, kaydırarak 10 kelime ileri/geri, konum çubuğu ve önizleme, sayfa görünümü, okurken ekranın kapanmaması (Android)
- **Temalar:** karanlık, aydınlık, sepya

## Geliştirme

Gereksinim: Flutter 3.24 veya üzeri (Dart 3.5+).

```bash
flutter pub get
flutter run            # bağlı cihaz veya emülatör
flutter run -d chrome  # web
```

Testler ve statik analiz:

```bash
flutter analyze
flutter test
```

## Proje yapısı

```
lib/
  main.dart                      Uygulama girişi, depolamanın açılması
  core/
    models/                      Book, RSVPSettings, WordToken
    services/
      rsvp_engine.dart           Oynatma motoru (zamanlama, ilerleme)
      library_storage.dart       Ayarlar ve okuma geçmişi (Hive)
      epub_extractor.dart        EPUB → düz metin
      pdf_extractor.dart         PDF → düz metin
      text_file_decoder.dart     TXT kodlama algılama
      text_cleaner.dart          Sayfa numarası / telif satırı temizliği
    utils/
      text_parser.dart           Metni RSVP kelimelerine ayırma
      orp_calculator.dart        Odak harfinin hesaplanması
      timing_calculator.dart     Kelime süreleri ve duraklamalar
  presentation/
    screens/                     Ana ekran, okuma ekranı, ayarlar
    widgets/orp_text_widget.dart Odak harfi ortalanmış kelime gösterimi
assets/fonts/                    Roboto Mono (uygulamaya gömülü)
test/                            Birim ve widget testleri
```

## Lisanslar

- **Roboto Mono** yazı tipi SIL Open Font License 1.1 ile lisanslıdır
  (`assets/fonts/OFL.txt`). Uygulamanın lisanslar sayfasında da listelenir.
- **syncfusion_flutter_pdf** açık kaynak değildir; Syncfusion lisansına
  tabidir. Uygulamayı ticari olarak yayınlamadan önce
  [Syncfusion Community License](https://www.syncfusion.com/products/communitylicense)
  şartlarına uyup uymadığınızı kontrol edin ya da ticari lisans alın.
