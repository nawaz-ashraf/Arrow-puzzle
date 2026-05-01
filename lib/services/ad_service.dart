import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;

/// Central ad manager — handles rewarded + interstitial ads.
///
/// Usage:
/// - Call [initialize] once at app start
/// - Call [showRewardedAd] when user needs hint/undo
/// - Call [showInterstitialAd] after every 3 completed levels
class AdService {
  static final AdService _instance = AdService._();
  static AdService get instance => _instance;
  AdService._();

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  bool _isInitialized = false;

  // ── Ad Unit IDs ──────────────────────────────────────────────────────────
  // Debug builds use Google test IDs to avoid invalid traffic.
  // Release builds use production IDs.
  String get _rewardedAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'   // Android test
          : 'ca-app-pub-3940256099942544/1712485313';  // iOS test
    }
    // Production — Android only (add iOS rewarded ID when available)
    return 'ca-app-pub-4392358942856616/9039604032';
  }

  String get _interstitialAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'   // Android test
          : 'ca-app-pub-3940256099942544/4411468910';  // iOS test
    }
    // Production — Android only (add iOS interstitial ID when available)
    return 'ca-app-pub-4392358942856616/9816446734';
  }

  // ── Initialize ──────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_isInitialized) return;
    await MobileAds.instance.initialize();
    _isInitialized = true;
    _loadRewardedAd();
    _loadInterstitialAd();
  }

  // ── Rewarded Ad ─────────────────────────────────────────────────────────

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          debugPrint('[AdService] Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdService] Rewarded ad failed: ${error.message}');
          _rewardedAd = null;
          // Retry after delay
          Future.delayed(const Duration(seconds: 30), _loadRewardedAd);
        },
      ),
    );
  }

  bool get isRewardedAdReady => _rewardedAd != null;

  /// Shows a rewarded ad. Calls [onReward] when the user earns the reward.
  /// Calls [onAdNotReady] if no ad is loaded.
  void showRewardedAd({
    required VoidCallback onReward,
    VoidCallback? onAdNotReady,
  }) {
    if (_rewardedAd == null) {
      onAdNotReady?.call();
      _loadRewardedAd();
      return;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd(); // Preload next
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        _loadRewardedAd();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (_, reward) {
        onReward();
      },
    );
  }

  // ── Interstitial Ad ─────────────────────────────────────────────────────

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          debugPrint('[AdService] Interstitial ad loaded');
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdService] Interstitial ad failed: ${error.message}');
          _interstitialAd = null;
          Future.delayed(const Duration(seconds: 30), _loadInterstitialAd);
        },
      ),
    );
  }

  /// Shows interstitial ad. Safe to call even if ad isn't loaded.
  void showInterstitialAd() {
    if (_interstitialAd == null) {
      _loadInterstitialAd();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
      },
    );

    _interstitialAd!.show();
  }

  // ── Cleanup ─────────────────────────────────────────────────────────────

  void dispose() {
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
  }
}
