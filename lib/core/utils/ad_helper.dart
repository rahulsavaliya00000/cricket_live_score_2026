import 'dart:async';
import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:cricket_live_score/core/di/injection_container.dart';
import 'package:cricket_live_score/core/services/revenue_cat_service.dart';
import 'package:cricket_live_score/core/services/remote_config_service.dart';
import 'package:gma_mediation_unity/gma_mediation_unity.dart';
import 'package:gma_mediation_ironsource/gma_mediation_ironsource.dart';

/// Represents a queued ad load request.
class _AdLoadRequest {
  final List<BannerAd> cache;
  final AdSize size;
  final void Function(BannerAd ad)? onLoaded;
  final void Function()? onFailed;
  final void Function()? onImpression;

  _AdLoadRequest({
    required this.cache,
    required this.size,
    this.onLoaded,
    this.onFailed,
    this.onImpression,
  });
}

class AdHelper {
  /// Global navigator key — set this from your MaterialApp to enable back-block overlay.
  static GlobalKey<NavigatorState>? navigatorKey;

  /// List of test device IDs to enable Ad Inspector and test ads.
  /// Find your ID in the console logs (look for "To get test ads on this device, call...")
  static List<String> testDeviceIds = [
    "C0CF96ED36B33E7C0F49654E9544084C",
  ];

  /// Updates the Mobile Ads request configuration with test devices.
  static Future<void> updateTestDevices() async {
    if (kIsWeb) return;
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(testDeviceIds: testDeviceIds),
    );
  }

  /// Initializes mediation-specific consent and settings.
  static Future<void> initMediation({bool hasConsent = true}) async {
    if (kIsWeb) return;
    
    // Small delay to ensure native plugin channels are fully registered
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Unity Ads Mediation consent
    try {
      GmaMediationUnity().setGDPRConsent(hasConsent);
    } catch (e) {
      debugPrint('⚠️ GmaMediationUnity init error: $e');
    }

    // IronSource Mediation consent
    try {
      GmaMediationIronsource().setConsent(hasConsent);
    } catch (e) {
      debugPrint('⚠️ GmaMediationIronsource init error: $e');
    }
  }

  /// Set to true when the user is premium — all ad calls become no-ops.
  static bool isPremium = false;

  static bool _isBackBlockActive = false;

  /// True when a fullscreen ad (interstitial/rewarded) is currently being shown.
  /// Used to suppress App Open Ad from triggering on false resumes.
  static bool get isFullscreenAdActive => _isBackBlockActive;

  /// Timestamp of when the last fullscreen ad was dismissed.
  /// Used to add a cooldown before App Open Ad can trigger.
  static DateTime? _lastAdDismissedTime;

  /// Pushes a transparent route that blocks the Android back button.
  static void _pushBackBlockOverlay() {
    final nav = navigatorKey?.currentState;
    if (nav == null || _isBackBlockActive) return;
    _isBackBlockActive = true;
    nav.push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (_, __, ___) =>
            const PopScope(canPop: false, child: SizedBox.shrink()),
        transitionDuration: Duration.zero,
      ),
    );
  }

  /// Pops the transparent back-block overlay.
  static void _popBackBlockOverlay() {
    final nav = navigatorKey?.currentState;
    if (nav == null || !_isBackBlockActive) return;
    _isBackBlockActive = false;
    _lastAdDismissedTime = DateTime.now();
    nav.pop();
  }

  static InterstitialAd? _interstitialAd;
  static DateTime? _interstitialLoadedTime;
  static int _requestCount = 0;
  static bool _isInterstitialLoading = false;
  static Completer<void>? _interstitialCompleter;

  /// True when an interstitial ad is loaded and not yet expired.
  static bool get isInterstitialAdReady =>
      _interstitialAd != null && !_isAdExpired(_interstitialLoadedTime);

  static RewardedAd? _rewardedAd;
  static DateTime? _rewardedLoadedTime;
  static bool _isRewardedLoading = false;

  static AppOpenAd? _appOpenAd;
  static DateTime? _appOpenLoadedTime;
  static bool _isAppOpenAdLoading = false;
  static int _appResumeCount = 0;

  static const Duration _adExpiration = Duration(hours: 4);

  static String get appOpenAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid || Platform.isIOS) {
      return RemoteConfigService.instance.adAppOpenId;
    } else {
      return '';
    }
  }

  // -- Preloaded Banner Ads Cache --
  static final List<BannerAd> _preloadedSmallBanners = [];
  static final List<BannerAd> _preloadedMediumBanners = [];

  static String get nativeAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid || Platform.isIOS) {
      return RemoteConfigService.instance.adBannerId;
    } else {
      return '';
    }
  }

  static String get interstitialAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid || Platform.isIOS) {
      return RemoteConfigService.instance.adInterstitialId;
    } else {
      return '';
    }
  }

  static String get rewardedAdUnitId {
    if (kIsWeb) return '';
    if (Platform.isAndroid || Platform.isIOS) {
      return RemoteConfigService.instance.adRewardedId;
    } else {
      return '';
    }
  }

  // Preloads ads. Call this primarily on app init.
  static Future<void> init() async {
    if (isPremium) return; // No ads to preload for premium users

    // On iOS, request tracking authorization for better ad targeting (Ad ID access)
    if (!kIsWeb && Platform.isIOS) {
      await requestTrackingAuthorization();
    }

    // Start banner preloading immediately — sequential, no simultaneous requests
    _fillBannerCaches();
    // Load interstitial immediately so it's ready before onboarding finishes
    loadInterstitialAd();
    Future.delayed(const Duration(seconds: 2), () {
      loadRewardedAd();
    });
    Future.delayed(const Duration(seconds: 4), () {
      loadAppOpenAd(); // Pre-warm so resume-5 is always instant
    });

    // Initialize mediation with a delay
    unawaited(initMediation());
  }

  /// Requests the App Tracking Transparency (ATT) authorization on iOS.
  /// This allows AdMob to access the IDFA for personalized ads.
  static Future<void> requestTrackingAuthorization() async {
    if (kIsWeb || !Platform.isIOS) return;

    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        // Wait a small bit to ensure the app is in the foreground
        await Future.delayed(const Duration(milliseconds: 1000));
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } catch (e) {
      debugPrint('⚠️ AdHelper: Error requesting tracking authorization: $e');
    }
  }

  // Ensures we always have 2 medium + 2 small banners ready
  static void _fillBannerCaches() {
    _queueFillCache(_preloadedMediumBanners, AdSize.mediumRectangle, 2);
    _queueFillCache(
      _preloadedSmallBanners,
      const AdSize(width: 320, height: 100),
      2,
    );
  }

  // --- Sequential Ad Loading Queue ---
  static final List<_AdLoadRequest> _adQueue = [];
  static bool _isLoadingAd = false;

  /// Queues up banner ads to load one-by-one (no simultaneous requests).
  static void _queueFillCache(
    List<BannerAd> cache,
    AdSize size,
    int targetCount,
  ) {
    if (isPremium) return;
    int needed = targetCount - cache.length;
    debugPrint('📊 [AD_QUEUE] _queueFillCache -> Cache size: ${cache.length}/$targetCount. Queuing $needed ads of size $size.');
    for (int i = 0; i < needed; i++) {
      _adQueue.add(_AdLoadRequest(cache: cache, size: size));
    }
    _processQueue();
  }

  /// Process the next ad in the queue. Only one loads at a time.
  static void _processQueue() {
    debugPrint('🚦 [AD_QUEUE] _processQueue checking in... is_loading: $_isLoadingAd | queue_length: ${_adQueue.length}');
    if (isPremium || _isLoadingAd || _adQueue.isEmpty) return;
    _isLoadingAd = true;

    final request = _adQueue.removeAt(0);
    final isCallbackRequest = request.onLoaded != null;
    debugPrint('⏳ [AD_QUEUE] Loading next ad: size=${request.size}, isCallback=$isCallbackRequest');

    try {
      final ad = BannerAd(
        adUnitId: nativeAdUnitId,
        size: request.size,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (loadedAd) {
            debugPrint('✅ [AD_QUEUE] BannerAd LOADED successfully! (size=${request.size})');
            _isLoadingAd = false;
            if (isCallbackRequest) {
              request.onLoaded!(loadedAd as BannerAd);
            } else {
              // Only add to cache AFTER the ad is fully loaded
              request.cache.add(loadedAd as BannerAd);
              debugPrint('📦 [AD_QUEUE] Added ad to cache. New cache size: ${request.cache.length}');
            }
            _processQueue(); // Load next in queue
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint('❌💀 [AD_QUEUE] BannerAd FAILED to load: $error');
            ad.dispose();
            _isLoadingAd = false;
            if (isCallbackRequest) {
              request.onFailed?.call();
            }
            // Retry after delay, then continue queue
            debugPrint('⏳ [AD_QUEUE] Retrying queue processing in 5 seconds due to failure...');
            Future.delayed(const Duration(seconds: 5), () {
              _processQueue();
            });
          },
          onAdImpression: (ad) {
            debugPrint('👀 [AD_QUEUE] BannerAd Impression Fired!');
            request.onImpression?.call();
          },
        ),
      );

      ad.load();
      debugPrint('📡 [AD_QUEUE] ad.load() triggered.');
    } catch (e, st) {
      debugPrint('💥🆘 [AD_QUEUE] CRITICAL EXCEPTION during ad.load(): $e\n$st');
      _isLoadingAd = false;
      _processQueue(); // Don't let the queue die permanently
    }
  }

  /// Queue a single adaptive-width banner for a widget callback.
  /// Returns immediately — calls [onLoaded] when the ad is ready.
  /// Optionally calls [onImpression] when the SDK fires its first impression.
  static void loadAdaptiveBanner({
    required AdSize size,
    required void Function(BannerAd ad) onLoaded,
    required void Function() onFailed,
    void Function()? onImpression,
  }) {
    if (isPremium) return;
    _adQueue.add(
      _AdLoadRequest(
        cache: [], // not cached
        size: size,
        onLoaded: onLoaded,
        onFailed: onFailed,
        onImpression: onImpression,
      ),
    );
    _processQueue();
  }

  static BannerAd? getBannerAd(AdSize size) {
    if (isPremium) return null;
    List<BannerAd> cache = (size == AdSize.mediumRectangle)
        ? _preloadedMediumBanners
        : _preloadedSmallBanners;

    if (cache.isNotEmpty) {
      debugPrint('🎁 [AD_POOL] Cache HIT for $size! Returning preloaded ad. (Remaining cache: ${cache.length - 1})');
      final preloaded = cache.removeAt(0);
      _fillBannerCaches(); // top up cache
      return preloaded;
    }
    // Cache empty — caller should fall back to loadAdaptiveBanner
    debugPrint('📉 [AD_POOL] Cache MISS for $size! Pool is empty.');
    _fillBannerCaches(); // start refilling for next time
    return null;
  }

  /// Call this after an ad has been shown and dismissed / scrolled off.
  /// Disposes the old ad and triggers a cache top-up so new fresh ads are ready.
  static void releaseAd(BannerAd? ad) {
    ad?.dispose();
    _fillBannerCaches();
  }

  /// Checks if a loaded ad is expired (stale).
  static bool _isAdExpired(DateTime? loadedTime) {
    if (loadedTime == null) return true;
    return DateTime.now().isAfter(loadedTime.add(_adExpiration));
  }

  static Future<void> loadInterstitialAd({
    bool showAfterLoad = false,
    VoidCallback? onAdDismissed,
  }) async {
    if (isPremium || kIsWeb) return;

    // Check if already loaded but expired
    if (_interstitialAd != null && _isAdExpired(_interstitialLoadedTime)) {
      print('🗑️ AdHelper: Disposing expired Interstitial Ad');
      _interstitialAd?.dispose();
      _interstitialAd = null;
    }

    if (_interstitialAd != null) {
      if (showAfterLoad) _showLoadedInterstitialAd(onAdDismissed ?? () {});
      return;
    }

    if (_isInterstitialLoading) {
      if (_interstitialCompleter != null) {
        await _interstitialCompleter!.future;
        if (showAfterLoad) _showLoadedInterstitialAd(onAdDismissed ?? () {});
      }
      return;
    }

    print(
      '🚀 AdHelper: Loading Interstitial Ad (ShowAfterLoad: $showAfterLoad)...',
    );
    _isInterstitialLoading = true;
    _interstitialCompleter = Completer<void>();

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('✅ AdHelper: Interstitial Ad Loaded');
          _interstitialAd = ad;
          _interstitialLoadedTime = DateTime.now();
          _isInterstitialLoading = false;
          _interstitialCompleter?.complete();
          _interstitialCompleter = null;
          if (showAfterLoad) _showLoadedInterstitialAd(onAdDismissed ?? () {});
        },
        onAdFailedToLoad: (error) {
          print('❌ AdHelper: Interstitial Ad failed: $error');
          _interstitialAd = null;
          _isInterstitialLoading = false;
          _interstitialCompleter?.complete();
          _interstitialCompleter = null;
          if (onAdDismissed != null) onAdDismissed();
          Future.delayed(
            const Duration(seconds: 30),
            () => loadInterstitialAd(),
          );
        },
      ),
    );

    return _interstitialCompleter?.future;
  }

  // ─── INTERSTITIAL FREQUENCY ──────────────────────────────────────────────
  // Change _interstitialEvery to control how often interstitial ads show.
  // e.g. 3 = every 3rd navigation, 5 = every 5th navigation, etc.
  static int get _interstitialEvery => RemoteConfigService.instance.adInterstitialEvery;
  static int get _premiumPromoEvery => RemoteConfigService.instance.adPremiumPromoEvery;
  // ─────────────────────────────────────────────────────────────────────────

  static void showInterstitialAd(VoidCallback onAdDismissed) {
    // Premium users never see interstitial ads
    if (isPremium) {
      onAdDismissed();
      return;
    }

    _requestCount++;
    print(
      '🚀 AdHelper: Interstitial turn count: $_requestCount (Shows every ${_interstitialEvery}th)',
    );

    // If it's the premium promo turn, show the 'Remove Ads' dialog instead
    if (_requestCount > 0 && _requestCount % _premiumPromoEvery == 0) {
      print('🎁 AdHelper: Time to show the Premium Promo Dialog (Turn $_requestCount)!');
      final nav = navigatorKey?.currentState;
      if (nav != null && nav.context.mounted) {
        showDialog(
          context: nav.context,
          barrierDismissible: false,
          builder: (context) => _PremiumPromoDialog(onDismissed: onAdDismissed),
        );
        return; // Skip interstitial ad logic for this promo turn
      }
    }

    // 1-Step-Ahead Preloading: Load one turn before so it's ready in time.
    if (_requestCount % _interstitialEvery == _interstitialEvery - 1) {
      print(
        '📥 AdHelper: Preloading Interstitial (Turn ${_interstitialEvery - 1}/$_interstitialEvery)...',
      );
      loadInterstitialAd();
    }

    if (_requestCount % _interstitialEvery == 0) {
      showInterstitialAdImmediately(onAdDismissed);
    } else {
      onAdDismissed();
    }
  }

  static void showInterstitialAdImmediately(VoidCallback onAdDismissed) {
    if (isPremium) {
      onAdDismissed();
      return;
    }
    print('🎬 AdHelper: Showing Interstitial Ad immediately...');
    if (_interstitialAd != null && !_isAdExpired(_interstitialLoadedTime)) {
      _showLoadedInterstitialAd(onAdDismissed);
    } else {
      print('⚠️ AdHelper: Interstitial not ready/expired - loading with indicator...');
      final nav = navigatorKey?.currentState;
      if (nav == null) {
        loadInterstitialAd();
        onAdDismissed();
        return;
      }
      
      nav.push(
        PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black54,
          barrierDismissible: false,
          pageBuilder: (_, __, ___) => const _InterstitialLoadingDialog(),
          transitionDuration: Duration.zero,
        ),
      );

      bool timerTriggered = false;
      void handleResult() {
        if (timerTriggered) return;
        timerTriggered = true;
        
        // Pop the dialog
        nav.pop();

        if (_interstitialAd != null && !_isAdExpired(_interstitialLoadedTime)) {
          // Small delay so dialog close animates before ad shows
          Future.delayed(const Duration(milliseconds: 150), () {
            _showLoadedInterstitialAd(onAdDismissed);
          });
        } else {
          onAdDismissed();
        }
      }

      // Timeout after 6s
      Timer(const Duration(seconds: 6), handleResult);

      // Start loading (or await existing load)
      loadInterstitialAd().then((_) => handleResult());
    }
  }

  static void _showLoadedInterstitialAd(VoidCallback onAdDismissed) {
    if (_interstitialAd == null) {
      onAdDismissed();
      return;
    }
    _pushBackBlockOverlay();
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _popBackBlockOverlay();
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _popBackBlockOverlay();
        onAdDismissed();
      },
    );
    _interstitialAd!.setImmersiveMode(true);
    _interstitialAd!.show();
    _interstitialAd = null;
  }

  static void loadRewardedAd() {
    if (kIsWeb) return;
    
    if (_rewardedAd != null && _isAdExpired(_rewardedLoadedTime)) {
      _rewardedAd?.dispose();
      _rewardedAd = null;
    }
    if (_isRewardedLoading || _rewardedAd != null) return;

    _isRewardedLoading = true;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _rewardedLoadedTime = DateTime.now();
          _isRewardedLoading = false;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isRewardedLoading = false;
        },
      ),
    );
  }

  static void showRewardedAd({
    required Function(RewardItem) onEarnedReward,
    required VoidCallback onAdDismissed,
  }) {
    // Rewarded ads are mandatory for everyone (including premium) 
    // because they are used for "Watch & Earn" and "Live Feed unlocking".
    
    if (_rewardedAd != null && !_isAdExpired(_rewardedLoadedTime)) {
      _pushBackBlockOverlay();
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedAd = null;
          loadRewardedAd();
          _popBackBlockOverlay();
          onAdDismissed();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _rewardedAd = null;
          loadRewardedAd();
          _popBackBlockOverlay();
          onAdDismissed();
        },
      );
      _rewardedAd!.setImmersiveMode(true);
      _rewardedAd!.show(
        onUserEarnedReward: (_, reward) => onEarnedReward(reward),
      );
      _rewardedAd = null;
    } else {
      // Show loading overlay while ad fetches, then show it
      print('⚠️ AdHelper: Rewarded ad not ready — loading with indicator...');
      final nav = navigatorKey?.currentState;
      if (nav == null) {
        loadRewardedAd();
        onAdDismissed();
        return;
      }
      // Show a loading dialog
      nav.push(
        PageRouteBuilder(
          opaque: false,
          barrierColor: Colors.black54,
          barrierDismissible: false,
          pageBuilder: (_, __, ___) => const _RewardedLoadingDialog(),
          transitionDuration: Duration.zero,
        ),
      );

      // Load with timeout
      bool dialogClosed = false;
      void closeDialog() {
        if (!dialogClosed) {
          dialogClosed = true;
          nav.pop();
        }
      }

      // Timeout after 8s — don't keep user waiting forever
      Timer(const Duration(seconds: 8), () {
        if (!dialogClosed) {
          closeDialog();
          loadRewardedAd();
          onAdDismissed();
        }
      });

      loadRewardedAd();
      // Poll until loaded
      Timer.periodic(const Duration(milliseconds: 300), (timer) {
        if (_rewardedAd != null && !_isAdExpired(_rewardedLoadedTime)) {
          timer.cancel();
          closeDialog();
          // Small delay so dialog close animates before ad shows
          Future.delayed(const Duration(milliseconds: 150), () {
            showRewardedAd(
              onEarnedReward: onEarnedReward,
              onAdDismissed: onAdDismissed,
            );
          });
        } else if (dialogClosed) {
          timer.cancel();
        }
      });
    }
  }

  static void loadAppOpenAd({
    bool showAfterLoad = false,
    VoidCallback? onAdDismissed,
  }) {
    if (isPremium || kIsWeb) return;

    if (_appOpenAd != null && _isAdExpired(_appOpenLoadedTime)) {
      print('🗑️ AdHelper: Disposing expired App Open Ad');
      _appOpenAd?.dispose();
      _appOpenAd = null;
    }

    if (_appOpenAd != null) {
      if (showAfterLoad) _showLoadedAppOpenAd(onAdDismissed ?? () {});
      return;
    }

    if (_isAppOpenAdLoading) return;

    final unitId = appOpenAdUnitId;
    if (unitId.isEmpty) {
      if (onAdDismissed != null) onAdDismissed();
      return;
    }

    print(
      '🚀 AdHelper: Loading App Open Ad (ShowAfterLoad: $showAfterLoad)...',
    );
    _isAppOpenAdLoading = true;
    AppOpenAd.load(
      adUnitId: unitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          print('✅ AdHelper: App Open Ad Loaded successfully');
          _appOpenAd = ad;
          _appOpenLoadedTime = DateTime.now();
          _isAppOpenAdLoading = false;
          if (showAfterLoad) _showLoadedAppOpenAd(onAdDismissed ?? () {});
        },
        onAdFailedToLoad: (error) {
          print('❌ AdHelper: App Open Ad failed: $error');
          _appOpenAd = null;
          _isAppOpenAdLoading = false;
          if (onAdDismissed != null) onAdDismissed();
          if (!error.message.contains('Too many recently failed requests')) {
            Future.delayed(const Duration(seconds: 30), () => loadAppOpenAd());
          }
        },
      ),
    );
  }

  static void _showLoadedAppOpenAd(VoidCallback onAdDismissed) {
    if (_appOpenAd == null) {
      print('❌ AdHelper: _showLoadedAppOpenAd called but _appOpenAd is null!');
      onAdDismissed();
      return;
    }
    print('🎬 AdHelper: Showing loaded App Open Ad...');
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        print('✅ AdHelper: App Open Ad is now visible on screen');
      },
      onAdDismissedFullScreenContent: (ad) {
        print('👋 AdHelper: App Open Ad dismissed by user');
        ad.dispose();
        _appOpenAd = null;
        onAdDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('❌ AdHelper: App Open Ad failed to SHOW: ${error.message}');
        ad.dispose();
        _appOpenAd = null;
        onAdDismissed();
      },
    );
    _appOpenAd!.show();
    _appOpenAd = null;
  }

  static void showAppOpenAd(VoidCallback onAdDismissed) {
    // Premium users never see app-open ads
    if (isPremium) {
      onAdDismissed();
      return;
    }

    print(
      '\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
      '📲 AdHelper: showAppOpenAd() called\n'
      '   ├─ _isBackBlockActive   : $_isBackBlockActive\n'
      '   ├─ _lastAdDismissedTime : $_lastAdDismissedTime\n'
      '   ├─ _appOpenAd loaded    : ${_appOpenAd != null}\n'
      '   ├─ _appOpenLoadedTime   : $_appOpenLoadedTime\n'
      '   ├─ _isAppOpenAdLoading  : $_isAppOpenAdLoading\n'
      '   └─ _appResumeCount so far: $_appResumeCount\n'
      '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━',
    );

    // Skip if a fullscreen ad (interstitial/rewarded) is currently active
    if (_isBackBlockActive) {
      print('⏭️ AdHelper: SKIPPED — fullscreen ad is active');
      onAdDismissed();
      return;
    }

    // Skip if a fullscreen ad was dismissed less than 3 seconds ago (false resume)
    if (_lastAdDismissedTime != null) {
      final secsSinceDismiss = DateTime.now()
          .difference(_lastAdDismissedTime!)
          .inSeconds;
      print('⏱️ AdHelper: Secs since last ad dismissed: $secsSinceDismiss');
      if (secsSinceDismiss < 3) {
        print('⏭️ AdHelper: SKIPPED — cooldown after fullscreen ad dismiss');
        onAdDismissed();
        return;
      }
    }

    _appResumeCount++;
    final nextTriggerAt = ((_appResumeCount ~/ 5) + 1) * 5;
    print(
      '� AdHelper: Resume count = $_appResumeCount '
      '(next App Open triggers at count $nextTriggerAt)',
    );

    // 1-Step-Ahead Preloading: Load on the 4th turn so it's ready for the 5th.
    if (_appResumeCount % 5 == 4) {
      print('📥 AdHelper: Preloading App Open Ad (count 4/5)...');
      loadAppOpenAd();
    }

    if (_appResumeCount % 5 == 0) {
      print('� AdHelper: Count hit multiple of 5 — attempting App Open Ad...');
      if (_appOpenAd != null && !_isAdExpired(_appOpenLoadedTime)) {
        print('✅ AdHelper: Ad is ready — showing now!');
        _showLoadedAppOpenAd(onAdDismissed);
      } else {
        final expired = _isAdExpired(_appOpenLoadedTime);
        print(
          '⚠️ AdHelper: Ad NOT ready '
          '(ad null: ${_appOpenAd == null}, expired: $expired) '
          '— loading lazily...',
        );
        loadAppOpenAd(showAfterLoad: true, onAdDismissed: onAdDismissed);
      }
    } else {
      print('⏭️ AdHelper: Not yet time (${_appResumeCount % 5}/5) — skipping');
      onAdDismissed();
    }
  }
}

/// Loading dialog shown while a rewarded ad is being fetched.
class _RewardedLoadingDialog extends StatelessWidget {
  const _RewardedLoadingDialog();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.amber),
              SizedBox(height: 16),
              Text(
                'Loading your reward...',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Loading dialog shown while an interstitial ad is being fetched.
class _InterstitialLoadingDialog extends StatelessWidget {
  const _InterstitialLoadingDialog();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.green),
              SizedBox(height: 16),
              Text(
                'Loading..',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Promotional Dialog shown every X navigations to encourage Ad-Free subscription.
class _PremiumPromoDialog extends StatefulWidget {
  final VoidCallback onDismissed;

  const _PremiumPromoDialog({required this.onDismissed});

  @override
  State<_PremiumPromoDialog> createState() => _PremiumPromoDialogState();
}

class _PremiumPromoDialogState extends State<_PremiumPromoDialog> {
  final _rcService = sl<RevenueCatService>();
  bool _isLoading = true;
  bool _isPurchasing = false;
  Package? _lifetimePackage;
  String _priceString = '₹49.00'; // Fallback if network fails

  @override
  void initState() {
    super.initState();
    _loadPackage();
  }

  Future<void> _loadPackage() async {
    try {
      final packages = await _rcService.getAvailablePackages();
      for (final p in packages) {
        if (p.identifier == '\$rc_lifetime') {
          _lifetimePackage = p;
          _priceString = p.storeProduct.priceString;
          break;
        }
      }
    } catch (_) {
      // Keep fallback price
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _purchaseLifetime() async {
    if (_lifetimePackage == null) return;
    
    setState(() => _isPurchasing = true);
    
    final result = await _rcService.purchasePackage(_lifetimePackage!);
    
    if (!mounted) return;
    
    setState(() => _isPurchasing = false);
    
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Welcome to Premium! You are now ad-free.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(); // Close dialog
      widget.onDismissed();
    } else if (result.errorMessage != 'cancelled') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Purchase failed.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildFeatureRow(IconData icon, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icon / Header
            Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: isDark ? 0.1 : 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.amber,
                  size: 44,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Enjoying Cricket Live Score?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Upgrade to Lifetime Premium and get exclusive access to advanced features.',
              style: TextStyle(
                fontSize: 13,
                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.7),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Features List
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildFeatureRow(Icons.block_flipped, 'Lifetime Ad-Free Experience', isDark),
                  _buildFeatureRow(Icons.picture_in_picture_alt_rounded, 'PIP (Picture in Picture) View', isDark),
                  _buildFeatureRow(Icons.offline_bolt_rounded, '2 Ball Advanced (Live Highlights)', isDark),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Purchase Button
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading || _isPurchasing ? null : _purchaseLifetime,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.amber.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading || _isPurchasing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black54,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Get Lifetime - $_priceString',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Not Now Button
            SizedBox(
              height: 44,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  widget.onDismissed(); // Allow the underlying action to continue
                },
                style: TextButton.styleFrom(
                  foregroundColor:
                      (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Not Now',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
