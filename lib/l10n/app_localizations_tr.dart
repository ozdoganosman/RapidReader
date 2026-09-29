// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get cancel => 'İptal';

  @override
  String get save => 'Kaydet';

  @override
  String get delete => 'Sil';

  @override
  String get modeSpeed => 'Hızlı Okuma';

  @override
  String get modeSpeedHint => 'Kelime kelime, seçtiğin hızda';

  @override
  String get modePlain => 'Düz Metin';

  @override
  String get modePlainHint => 'Sayfa olarak, kendi hızında';

  @override
  String get continueReading => 'Devam Et';

  @override
  String continueProgress(int percent, String mode) {
    return '%$percent · $mode';
  }

  @override
  String get sharedContentUnreadable => 'Paylaşılan içerik okunamadı';

  @override
  String get library => 'Kitaplık';

  @override
  String get readingSpeed => 'Okuma Hızı';

  @override
  String get wordsPerMinuteShort => 'kelime/dk';

  @override
  String get adjust => 'Ayarla';

  @override
  String get quranCardSubtitle => 'Arapça aslından meal';

  @override
  String chaptersAndTime(int count, String time) {
    return '$count bölüm · $time';
  }

  @override
  String wordCount(int count) {
    return '$count kelime';
  }

  @override
  String get addText => 'Metin Ekle';

  @override
  String get addTextHint => 'Kendi metnini ekle';

  @override
  String get addTextTitle => 'Yeni Metin Ekle';

  @override
  String get addCoverOptional => 'Kapak Resmi Ekle (Opsiyonel)';

  @override
  String get titleLabel => 'Başlık *';

  @override
  String get titleMissing => 'Başlık gerekli';

  @override
  String get authorLabel => 'Yazar (Opsiyonel)';

  @override
  String fileUnreadableWithError(String error) {
    return 'Dosya okunamadı: $error';
  }

  @override
  String get readingFile => 'Dosya okunuyor…';

  @override
  String get importFromFile => 'Dosyadan Yükle (TXT, PDF, EPUB)';

  @override
  String get fromClipboard => 'Panodan';

  @override
  String get clipboardEmpty => 'Panoda metin yok';

  @override
  String get webAddress => 'Web Adresi';

  @override
  String get contentLabel => 'Metin İçeriği *';

  @override
  String get contentMissing => 'Metin gerekli';

  @override
  String get readWithoutSaving => 'Kaydetmeden Oku';

  @override
  String get saveFailed =>
      'Metin kaydedilemedi. Cihazın depolama alanı için çok büyük olabilir.';

  @override
  String get textAdded => 'Metin başarıyla eklendi!';

  @override
  String get webArticle => 'Web makalesi';

  @override
  String get fetch => 'Getir';

  @override
  String pageUnreadableWithError(String error) {
    return 'Sayfa okunamadı: $error';
  }

  @override
  String get deleteText => 'Metni Sil';

  @override
  String deleteTextConfirm(String title) {
    return '\"$title\" metnini silmek istediğinize emin misiniz?';
  }

  @override
  String get textDeleted => 'Metin silindi';

  @override
  String durationSeconds(int seconds) {
    return '$seconds sn';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes dk';
  }

  @override
  String durationMinutesSeconds(int minutes, int seconds) {
    return '$minutes dk $seconds sn';
  }

  @override
  String durationHours(int hours) {
    return '$hours sa';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours sa $minutes dk';
  }

  @override
  String get settings => 'Ayarlar';

  @override
  String get unsavedChanges => 'Kaydedilmemiş Değişiklikler';

  @override
  String get unsavedChangesBody =>
      'Ayarlarda yaptığınız değişiklikler kaydedilmedi. Ne yapmak istersiniz?';

  @override
  String get discardAndExit => 'Çıkış (Kaydetme)';

  @override
  String get saveAndExit => 'Kaydet ve Çık';

  @override
  String get wordsPerMinuteLabel => 'Kelime/Dakika (WPM)';

  @override
  String get adaptiveSpeed => 'Adaptif Hız';

  @override
  String get adaptiveSpeedHint => 'Kısa kelimeler hızlı, uzun kelimeler yavaş';

  @override
  String get speedWarmUp => 'Hız Isınması';

  @override
  String get speedWarmUpHint => 'Yavaş başla, birkaç saniyede seçilen hıza çık';

  @override
  String get speedRamp => 'Kademeli Hızlanma';

  @override
  String speedRampHint(int step) {
    return 'Okurken hız her dakika $step kelime artar, hedefte durur';
  }

  @override
  String get targetSpeed => 'Hedef Hız';

  @override
  String get wordGrouping => 'Kelime Gruplama';

  @override
  String get chunkSize => 'Chunk Boyutu';

  @override
  String get display => 'Görünüm';

  @override
  String get fontSize => 'Font Boyutu';

  @override
  String get orpHighlight => 'ORP Vurgulama';

  @override
  String get orpHighlightHint => 'Odak noktasını kırmızı ile vurgula';

  @override
  String get focusGuides => 'Odak Çizgileri';

  @override
  String get focusGuidesHint => 'Dikey hizalama çizgilerini göster';

  @override
  String get fontFamily => 'Font Ailesi';

  @override
  String get fontMonoHint => 'Monospace - Sabit genişlik';

  @override
  String get fontRobotoHint => 'Sans-serif - Modern';

  @override
  String get fontOpenSansHint => 'Sans-serif - Okunabilir';

  @override
  String get fontNotoSansHint => 'Sans-serif - Çok dilli';

  @override
  String get fontLatoHint => 'Sans-serif - Zarif';

  @override
  String get fontMontserratHint => 'Sans-serif - Cesur';

  @override
  String get fontMerriweatherHint => 'Serif - Klasik';

  @override
  String get fontRobotoSlabHint => 'Slab Serif - Güçlü';

  @override
  String get fontOpenDyslexicHint => 'Disleksi dostu - Harfler karışmaz';

  @override
  String get theme => 'Tema';

  @override
  String get themeDark => 'Karanlık';

  @override
  String get themeLight => 'Aydınlık';

  @override
  String get themeSepia => 'Sepia';

  @override
  String get themeHighContrast => 'Yüksek Kontrast';

  @override
  String get cognitivePause => 'Bilişsel Duraklama';

  @override
  String get microPause => 'Mikro-Duraklama';

  @override
  String microPauseEvery(int count) {
    return 'Her $count cümlede bir duraklama';
  }

  @override
  String get off => 'Devre dışı';

  @override
  String get pauseInterval => 'Duraklama Aralığı';

  @override
  String sentenceCount(int count) {
    return '$count cümle';
  }

  @override
  String get privacy => 'Gizlilik';

  @override
  String get adConsent => 'Reklam izinleri';

  @override
  String get adConsentHint => 'Kişisel verilerle reklam iznini değiştir';

  @override
  String get resetDefaults => 'Varsayılanlara Sıfırla';

  @override
  String get language => 'Dil';

  @override
  String get languageDevice => 'Cihaz dili';

  @override
  String get readingComplete => 'Okuma Tamamlandı!';

  @override
  String remainingAndTotal(String remaining, String total) {
    return 'Kalan: $remaining / Toplam: $total';
  }

  @override
  String get tapLeftEdgeHint => 'Sol kenara dokun: cümle başına dön';

  @override
  String get pageView => 'Sayfa Görünümü';

  @override
  String wordPosition(int current, int total) {
    return 'Kelime $current / $total';
  }

  @override
  String get chapterComplete => 'Bölüm Tamamlandı!';

  @override
  String get nextChapter => 'Sonraki Bölüm';

  @override
  String get backToHome => 'Ana Sayfaya Dön';

  @override
  String get searchSurah => 'Sure ara (ad ya da numara)';

  @override
  String get revelationOrder => 'İniş sırası';

  @override
  String get mushafOrder => 'Mushaf sırası';

  @override
  String revelationNumber(int number) {
    return 'İniş $number';
  }

  @override
  String mushafNumber(int number) {
    return 'Mushaf $number';
  }

  @override
  String get arabicText => 'Arapça metin';

  @override
  String get arabicTextUnavailable => 'Arapça metin yüklenemedi';

  @override
  String get arabicTextSource =>
      'Arapça metin: Tanzil Projesi (tanzil.net), değiştirilmeden kullanılmıştır. CC BY 3.0';

  @override
  String get pageSettings => 'Sayfa ayarları';

  @override
  String get guidedReading => 'Rehberli okuma';

  @override
  String get stopGuidedReading => 'Rehberli okumayı durdur';

  @override
  String get slower => 'Yavaşlat';

  @override
  String get faster => 'Hızlandır';

  @override
  String get pageThemeLight => 'Açık';

  @override
  String get pageThemeSepia => 'Sepya';

  @override
  String get pageThemeGray => 'Gri';

  @override
  String get pageThemeDark => 'Koyu';

  @override
  String get pageThemeNight => 'Gece';

  @override
  String get pageFont => 'Yazı tipi';

  @override
  String get pageTextSize => 'Yazı boyutu';

  @override
  String get pageBackground => 'Arka plan';

  @override
  String get pageTextColor => 'Yazı rengi';

  @override
  String get pageBrightness => 'Parlaklık';

  @override
  String get enterValidUrl => 'Geçerli bir web adresi girin (https://...)';

  @override
  String get siteBlockedInBrowser =>
      'Tarayıcı güvenlik kuralları bu sitenin okunmasına izin vermiyor. Android uygulamasını kullanın ya da metni kopyalayıp \"Panodan\" ile yapıştırın.';

  @override
  String get pageDownloadFailed =>
      'Sayfa indirilemedi. İnternet bağlantınızı kontrol edin.';

  @override
  String pageOpenFailed(int status) {
    return 'Sayfa açılamadı (HTTP $status)';
  }

  @override
  String get noTextOnPage => 'Sayfada okunabilir metin bulunamadı';

  @override
  String get fileUnreadable => 'Dosya okunamadı';

  @override
  String unsupportedFileType(String extension) {
    return 'Desteklenmeyen dosya türü: .$extension';
  }

  @override
  String get noTextInFile => 'Dosyada okunabilir metin bulunamadı';

  @override
  String percent(int value) {
    return '%$value';
  }
}
