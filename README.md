# RapidReader

RSVP (Rapid Serial Visual Presentation) yöntemiyle hızlı okuma uygulaması.
Metin, kelime kelime ekranın ortasında gösterilir. Her kelimenin odak harfi
(ORP, Optimal Recognition Point) kırmızıyla vurgulanır ve hep aynı noktada,
odak çizgilerinin üzerinde durur; böylece göz satır boyunca hareket etmez.

Flutter ile yazılmıştır; Android ve web üzerinde çalışır.
Web sürümü: https://ozdoganosman.github.io/RapidReader/

## Özellikler

- **Hazır kütüphane:** İki Şehrin Hikâyesi (45 bölüm), Dönüşüm, Kur'an-ı Kerim ve Ömer Seyfettin
  hikâyeleri (Pembe İncili Kaftan, Bomba, Perili Köşk, Yüz Akı).
  Kitaplar bölüm listesiyle açılır; bölüm bitince "Sonraki Bölüm" ile devam edilir.
- **Kendi metnin:** Başlık, metin ve isteğe bağlı kapak resmiyle kütüphaneye eklenir
  (cihazda Hive ile, web'de IndexedDB'de saklanır; uzun kitaplar da sığar).
  Metin yazılabilir, panodan yapıştırılabilir, TXT/PDF/EPUB dosyasından yüklenebilir ya da
  bir web adresindeki makale getirilebilir. Android'de başka bir uygulamanın "Paylaş" menüsünden
  metin, bağlantı ya da dosya doğrudan RapidReader'a gönderilebilir. "Kaydetmeden Oku" ile
  metin kütüphaneye eklenmeden okunur. (Web sürümünde tarayıcı kuralları çoğu sitenin
  okunmasını engeller; orada metni kopyalayıp yapıştırmak gerekir.)
- **Kaldığın yerden devam:** Her kitabın ve bölümün okuma konumu ile ayarlar cihazda saklanır.
  Ana ekrandaki "Devam Et" kartı en son okunan bölümü son kullanılan modda açar; bölüm
  listesinde okunan bölümler işaretli, yarım kalanların yüzdesi yazılı.
- **Okuma ekranı:** Dokun-oynat/duraklat, kaydırarak 10 kelime ileri/geri, konum çubuğu
  ve önizleme, sayfa görünümü, kalan/toplam süre, okurken ekranın kapanmaması (Android).
- **Hızlı okuma ekranı:** Sol kenara dokununca cümlenin başına döner. Kelime grupları anlama
  göre kurulur ("ve", "bir" sonraki kelimeyle; "da", "ki", "gibi" önceki kelimeyle birlikte).
  Kademeli hızlanma: okurken hız her dakika 10 kelime artar, seçilen hedefte durur.
- **Ayarlar:** Hız (100–1000 kelime/dakika), uyarlanabilir hız, kelime gruplama (1–3),
  mikro-duraklama, hız ısınması (yavaş başlayıp seçilen hıza çıkma), font ailesi ve boyutu
  (disleksi dostu OpenDyslexic dahil), ORP vurgusu, odak çizgileri, temalar (yüksek kontrast dahil).
- **Üç okuma modu:** Bir bölüm ya da metin açılırken sorulur:
  - *Hızlı Okuma:* kelime kelime (RSVP), seçilen hızda.
  - *Düz Metin:* sayfa olarak. Sayfa ayarlarında (Aa) yazı tipi (Literata, Merriweather, Lora,
    Noto Serif, Roboto, Open Sans, Lato, OpenDyslexic), yazı boyutu, tema (Açık, Sepya, Gri, Koyu,
    göz yormayan sıcak renkli Gece), özel arka plan ve yazı rengi ile parlaklık seçilir.
    *Rehberli okuma:* sayfada seçilen hızda kelime kelime ilerleyen bir vurgu; göz onu izler.
  - *Sesli Okuma:* cihazın Türkçe sesiyle paragraf paragraf; okunan paragraf ve kelime
    işaretlenir, bir paragrafa dokununca oradan okunur, konuşma hızı 0,5x–2x. Android'de bölümün
    kalanı sese bir kerede verilir: paragraflar arasında duraklama olmaz ve ekran kapalıyken de
    okuma sürer; bölüm bitince sonraki bölüme geçer. Bildirimde ve kilit ekranında oynat/duraklat
    ile önceki/sonraki paragraf düğmeleri vardır; medya servisi uzun dinlemede Android'in
    uygulamayı kapatmasını önler. Cihazda Türkçe ses verisi olmalıdır
    (Ayarlar > Metin okuma çıkışı).

  Kalınan yer üç modda ortaktır (kelime olarak saklanır).
- **Kur'an-ı Kerim:** Sure adına ya da numarasına göre arama, iniş sırası ile mushaf
  sırası arasında geçiş, her surenin Arapça metni (Tanzil Projesi, Amiri Quran yazı tipiyle).
- **Türkçe desteği:** Kesme işaretli kelimeler (Türkiye'nin) tek kelime kalır; odak harfi
  noktalamaya, kesme işaretine veya tireye düşmez.

Kitap dosyaları `assets/books/` altındadır: `Seri_N.txt` bir bölüm, `Seri.jpg` serinin
kapağıdır (seri kapağı yoksa `Seri_N.jpg`; `.png` ve `.webp` de olur, ~600 piksel genişlik yeterli).
Dosyanın ilk satırı başlık, ikinci satırı yazar olarak okunur. Kütüphane açılışta
metinleri değil `assets/books/index.json` dizinini okur; metin, bölüm açılınca yüklenir.
Bu klasörde bir dosyayı ekledikten ya da değiştirdikten sonra dizini yenileyin:

```bash
dart run tool/build_book_index.dart
```

(`test/book_index_test.dart` dizin güncel değilse hata verir.)

## Geliştirme

Gereksinim: Flutter 3.47 (Dart 3.13). CI de bu sürümü kullanır.

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

**Otomatik test ve yayın:** `.github/workflows/ci.yml` her push ve pull request'te
analizi ve testleri çalıştırır. `master`'a yapılan her push testler geçerse web
sürümünü derleyip `gh-pages` dalına yayınlar; siteyi elle güncellemek gerekmez.
`web/` klasörüne konan sayfalar (ör. `privacy-policy.html`) da yayına girer.

**Release imzası:** `android/key.properties` ve `android/upload-keystore.jks` repoda
yoktur (bilerek; `android/.gitignore`). Release APK/AAB üretmek için bu iki dosyanın
yerel kopyası gerekir. Bu dosyaları kaybetmeyin ve paylaşmayın.

**Çökme raporları (Crashlytics, henüz kurulu değil):** Firebase Crashlytics için bir
Firebase projesi gerekir; yapılandırma dosyaları projeye özeldir ve repoda yoktur.
Kurmak için:

1. [Firebase konsolunda](https://console.firebase.google.com) proje oluşturup Android
   uygulamasını `com.rapidreader.rapid_reader` paket adıyla ekleyin.
2. `dart pub global activate flutterfire_cli` ve `flutterfire configure` çalıştırın
   (`lib/firebase_options.dart` ve `android/app/google-services.json` üretilir).
3. `flutter pub add firebase_core firebase_crashlytics`; `main()` içinde
   `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` sonrası
   `FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;` ve
   `PlatformDispatcher.instance.onError` ile yakalanmayan hataları kaydedin.
4. Gizlilik politikasına (`web/privacy-policy.html`) çökme raporlarında cihaz modeli, işletim
   sistemi sürümü, uygulama sürümü ve hata ayrıntılarının Google Firebase'e gönderildiğini ekleyin;
   Play Console'daki Veri Güvenliği formunda "Uygulama etkinliği / Kilitlenme günlükleri"ni işaretleyin.

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
      read_aloud_player.dart         Sesli okuma (flutter_tts, paragraf paragraf)
      read_aloud_notification.dart   Sesli okumanın bildirimi ve kilit ekranı (audio_service)
      ad_service.dart                AdMob banner ve geçiş reklamı
      epub_extractor.dart, pdf_extractor.dart, text_file_decoder.dart,
      text_cleaner.dart,
      document_importer.dart         TXT/PDF/EPUB dosyasından metin yükleme
    utils/
      text_parser.dart               Metni RSVP kelimelerine ayırma
      orp_calculator.dart            Odak harfinin hesaplanması
      timing_calculator.dart         Kelime süreleri ve duraklamalar
  presentation/
    screens/                         Ana ekran, bölüm listesi, okuma ekranı, ayarlar
    widgets/                         Odak harfi ortalanmış kelime gösterimi, banner reklam
assets/books/                        Hazır kitaplar ve kapakları
assets/google_fonts/                 Varsayılan fontlar (Roboto Mono, sayfa için Literata), çevrimdışı çalışsın diye
test/                                Birim ve widget testleri
```

## Lisanslar

- **Kitap metinleri:** İki Şehrin Hikâyesi, Dickens'ın İngilizce aslından
  (Project Gutenberg #98), Dönüşüm, Kafka'nın Almanca aslından (1917 Kurt Wolff
  baskısı, Project Gutenberg #22367) Türkçeye çevrildi (2026). Her iki asıl da
  kamu malıdır. Kur'an-ı Kerim meali Arapça aslından (Tanzil Projesi'nin "Simple"
  metni) yapay zekâ desteğiyle çevrilmiş ve ayet ayet ikinci kez gözden
  geçirilmiştir; yayından önce ehil bir kişiye okutulmalıdır. Sureler iniş
  sırasıyla dizilidir (`Kuran_1.txt` = Alak Suresi).
- **Ömer Seyfettin** (ö. 1920) hikâyeleri kamu malıdır. Metinler Vikikaynak'ın
  sadeleştirilmemiş aktarımlarıdır (GitHub'daki bir derlemeden alındı; sadeleştirme ve
  kısaltma yapılmadığı kontrol edildi). Yayından önce Dergâh'ın *Bütün Eserleri*
  baskısıyla karşılaştırılması önerilir.
- **Arapça Kur'an metni** (`assets/quran/`) Tanzil Projesi'nin "Simple" metnidir
  (tanzil.net, CC BY 3.0); değiştirilmeden kullanılır, kaynak uygulamada belirtilir
  (`assets/quran/SOURCE.txt`).
- **Amiri Quran** yazı tipi SIL Open Font License 1.1 ile lisanslıdır
  (`assets/fonts/AmiriQuran-OFL.txt`).
- **OpenDyslexic** yazı tipi Bitstream Vera lisansına dayalı serbest bir lisansla
  dağıtılır (`assets/fonts/OpenDyslexic-LICENSE.txt`).
- **Roboto Mono** yazı tipi SIL Open Font License 1.1 ile lisanslıdır
  (`assets/google_fonts/OFL.txt`) ve uygulamanın lisanslar sayfasında listelenir.
- **syncfusion_flutter_pdf** açık kaynak değildir; Syncfusion lisansına tabidir.
  Uygulamayı ticari olarak yayınlamadan önce
  [Syncfusion Community License](https://www.syncfusion.com/products/communitylicense)
  şartlarını kontrol edin ya da ticari lisans alın.
