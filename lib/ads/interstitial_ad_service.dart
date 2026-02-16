import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Singleton service that preloads and shows interstitial ads.
class InterstitialAdService {
  static final InterstitialAdService _instance = InterstitialAdService._();
  factory InterstitialAdService() => _instance;
  InterstitialAdService._();

  static const String _adUnitId = 'ca-app-pub-7659700279033478/3339413815';

  InterstitialAd? _ad;
  bool _isLoading = false;
  bool _isShowing = false;

  /// Preload an interstitial. Safe to call multiple times.
  Future<void> preload() async {
    if (_ad != null || _isLoading) return;
    _isLoading = true;

    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdService] Ad loaded');
          _ad = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdService] Ad failed to load: ${error.message}');
          _ad = null;
          _isLoading = false;
          // Retry after a delay
          Future.delayed(const Duration(seconds: 30), preload);
        },
      ),
    );
  }

  /// Show the ad if one is loaded. Returns true if shown, false otherwise.
  /// Never blocks gameplay — returns immediately if no ad is ready.
  Future<bool> showIfAvailable({required String placement}) async {
    debugPrint('[AdService] Ad show requested: placement=$placement');

    if (_ad == null || _isShowing) {
      debugPrint('[AdService] No ad available, skipping');
      // Trigger a preload in background for the next opportunity
      preload();
      return false;
    }

    _isShowing = true;
    final completer = Completer<bool>();

    _ad!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdService] Ad dismissed');
        ad.dispose();
        _ad = null;
        _isShowing = false;
        preload(); // Reload for next placement
        if (!completer.isCompleted) completer.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdService] Ad failed to show: ${error.message}');
        ad.dispose();
        _ad = null;
        _isShowing = false;
        preload();
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    await _ad!.show();
    debugPrint('[AdService] Ad shown');

    return completer.future;
  }
}
