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

  // Real interstitial ad unit: create one in AdMob and put its id here.
  // While it is empty, release builds show no interstitials (showing
  // Google's test ads to real users would earn nothing).
  static const String _interstitialAdUnitId = '';

  // Google's test interstitial, used in debug builds
  static const String _testInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  String get bannerAdUnitId => _bannerAdUnitId;

  /// Interstitial ad unit to use, or null when interstitials are disabled
  String? get interstitialAdUnitId {
    if (kDebugMode) return _testInterstitialAdUnitId;
    return _interstitialAdUnitId.isEmpty ? null : _interstitialAdUnitId;
  }

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
    final adUnitId = interstitialAdUnitId;
    if (adUnitId == null) return;

    InterstitialAd.load(
      adUnitId: adUnitId,
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

  /// Finished reading sessions since the last interstitial
  @visibleForTesting
  int get readingSessionCount => _readingSessionCount;

  /// Call when a book or chapter has been read to the end
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
