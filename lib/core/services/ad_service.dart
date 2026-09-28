import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  /// A separate service, for tests of the start-up
  @visibleForTesting
  AdService.test();

  bool _started = false;
  final _ready = Completer<bool>();
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

  /// Completes once the start-up is over: true when ads may be requested
  Future<bool> get ready => _ready.future;

  /// Ask for the ad consent where the law needs it, then start the ads SDK
  Future<void> initialize() async {
    if (_started) return;
    _started = true;
    if (!kIsWeb) {
      try {
        await _gatherConsent();
        // Also with the choice of an earlier start when the update failed
        if (await ConsentInformation.instance.canRequestAds()) {
          await MobileAds.instance.initialize();
          _isInitialized = true;
          _loadInterstitialAd();
        }
      } catch (e) {
        debugPrint('AdService initialization error: $e');
      }
    }
    _ready.complete(_isInitialized);
  }

  /// Google's consent message (EEA, UK, Switzerland), when it has to be
  /// shown; set up under "Gizlilik ve mesajlaşma" in AdMob
  Future<void> _gatherConsent() async {
    final updated = Completer<bool>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () => updated.complete(true),
      (error) {
        debugPrint('Consent info update failed: ${error.message}');
        updated.complete(false);
      },
    );
    // Without a network the ads wait no longer than this
    if (!await updated.future.timeout(const Duration(seconds: 10), onTimeout: () => false)) return;
    await ConsentForm.loadAndShowConsentFormIfRequired((error) {
      if (error != null) debugPrint('Consent form error: ${error.message}');
    });
  }

  /// Whether the settings have to offer changing the ad consent
  Future<bool> privacyOptionsRequired() async {
    if (kIsWeb) return false;
    await ready;
    try {
      return await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
    } catch (e) {
      return false;
    }
  }

  /// Google's form to change the ad consent
  Future<void> showPrivacyOptions() => ConsentForm.showPrivacyOptionsForm((error) {
        if (error != null) debugPrint('Privacy options error: ${error.message}');
      });

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
