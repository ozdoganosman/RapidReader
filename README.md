# RapidReader

RSVP (Rapid Serial Visual Presentation) yöntemiyle hızlı okuma uygulaması.
Metin, kelime kelime ekranın ortasında gösterilir. Her kelimenin odak harfi
(ORP, Optimal Recognition Point) kırmızıyla vurgulanır ve hep aynı noktada,
odak çizgilerinin üzerinde durur; böylece göz satır boyunca hareket etmez.

Flutter ile yazılmıştır; Android ve web üzerinde çalışır.
Web sürümü: https://ozdoganosman.github.io/RapidReader/

## Özellikler

- **Hazır kütüphane:** İki Şehrin Hikâyesi (45 bölüm), Dönüşüm, Kur'an-ı Kerim.
  Kitaplar bölüm listesiyle açılır; bölüm bitince "Sonraki Bölüm" ile devam edilir.
- **Kendi metnin:** Başlık, metin ve isteğe bağlı kapak resmiyle kütüphaneye eklenir.
- **Kaldığın yerden devam:** Her kitabın ve bölümün okuma konumu ile ayarlar cihazda saklanır.
- **Okuma ekranı:** Dokun-oynat/duraklat, kaydırarak 10 kelime ileri/geri, konum çubuğu
  ve önizleme, sayfa görünümü, kalan/toplam süre, okurken ekranın kapanmaması (Android).
- **Ayarlar:** Hız (100–1000 kelime/dakika), uyarlanabilir hız, kelime gruplama (1–3),
  mikro-duraklama, font ailesi ve boyutu, ORP vurgusu, odak çizgileri, temalar.
- **Türkçe desteği:** Kesme işaretli kelimeler (Türkiye'nin) tek kelime kalır; odak harfi
  noktalamaya, kesme işaretine veya tireye düşmez.

Kitap dosyaları `assets/books/` altındadır: `Seri_N.txt` bir bölüm, `Seri.png` serinin
kapağıdır. Dosyanın ilk satırı başlık, ikinci satırı yazar olarak okunur.

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

**Release imzası:** `android/key.properties` ve `android/upload-keystore.jks` repoda
yoktur (bilerek; `android/.gitignore`). Release APK/AAB üretmek için bu iki dosyanın
yerel kopyası gerekir. Bu dosyaları kaybetmeyin ve paylaşmayın.

## Proje yapısı

```
lib/
  main.dart                          Uygulama girişi, reklamların başlatılması
  core/
    models/                          Book, RSVPSettings, WordToken
    services/
      book_service.dart              assets/books kütüphanesini yükler
      custom_book_service.dart       Kullanıcının eklediği metinler
      reading_storage.dart           Ayarlar ve okuma konumları
      rsvp_engine.dart               Oynatma motoru (zamanlama, ilerleme)
      ad_service.dart                AdMob banner ve geçiş reklamı
      epub_extractor.dart, pdf_extractor.dart, text_file_decoder.dart,
      text_cleaner.dart              Dosya içe aktarma (şu an arayüze bağlı değil)
    utils/
      text_parser.dart               Metni RSVP kelimelerine ayırma
      orp_calculator.dart            Odak harfinin hesaplanması
      timing_calculator.dart         Kelime süreleri ve duraklamalar
  presentation/
    screens/                         Ana ekran, bölüm listesi, okuma ekranı, ayarlar
    widgets/                         Odak harfi ortalanmış kelime gösterimi, banner reklam
assets/books/                        Hazır kitaplar ve kapakları
assets/google_fonts/                 Varsayılan font (Roboto Mono), çevrimdışı çalışsın diye
test/                                Birim ve widget testleri
```

## Lisanslar

- **Roboto Mono** yazı tipi SIL Open Font License 1.1 ile lisanslıdır
  (`assets/google_fonts/OFL.txt`) ve uygulamanın lisanslar sayfasında listelenir.
- **syncfusion_flutter_pdf** açık kaynak değildir; Syncfusion lisansına tabidir.
  Uygulamayı ticari olarak yayınlamadan önce
  [Syncfusion Community License](https://www.syncfusion.com/products/communitylicense)
  şartlarını kontrol edin ya da ticari lisans alın.
