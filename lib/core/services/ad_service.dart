import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isInitialized = false;
  InterstitialAd? _interstitialAd;
  int _readingSessionCount = 0;

  // Real Ad IDs
  static const String _bannerAdUnitId = 'ca-app-pub-9234283093562204/3791543255';

  // Test Interstitial (henüz oluşturulmadı - gerekirse AdMob'dan oluştur)
  static const String _interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  String get bannerAdUnitId => _bannerAdUnitId;
  String get interstitialAdUnitId => _interstitialAdUnitId;

  Future<void> initialize() async {
    if (_isInitialized || kIsWeb) return;

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      _loadInterstitialAd();
    } catch (e) {
      debugPrint('AdService initialization error: $e');
    }
  }

  BannerAd createBannerAd({
    required void Function(Ad) onAdLoaded,
    required void Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    );
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  void onReadingSessionComplete() {
    _readingSessionCount++;
    // Show interstitial every 3 reading sessions
    if (_readingSessionCount >= 3) {
      showInterstitialAd();
      _readingSessionCount = 0;
    }
  }

  void showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
  }
}
