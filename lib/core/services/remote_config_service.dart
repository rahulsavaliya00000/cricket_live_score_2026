import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Wraps Firebase Remote Config.
/// All flags live inside a single JSON parameter called [kAppConfig].
///
/// Firebase Remote Config key:  app_config
/// Default value (paste this in Firebase Console as the default):
/// {
///   "skip_onboarding": false,     -- true = skip onboarding on first launch
///   "skip_tour": false,           -- true = skip home screen coach marks
///   "premium": false,             -- true = all users get premium for free
///   "spin_always_ready": false,   -- true = spin wheel never on cooldown
///   "show_wallet": true,          -- true = show wallet chip + spin button
///   "show_live_feed_button": true,-- true = show live feed button on home
///   "under_maintenance": false    -- true = show global maintenance block screen
/// }
class RemoteConfigService {
  RemoteConfigService._();
  static final RemoteConfigService instance = RemoteConfigService._();

  late final FirebaseRemoteConfig _rc;

  // ── Single key in Firebase Remote Config ──────────────────────────────────
  static const kAppConfig = 'app_config';
  static const kAdConfig = 'ad_config';

  // ── In-app default JSON (used when Remote Config is unreachable) ──────────
  // ⚠️  URLs are intentionally empty — they MUST be set in Firebase Console.
  //     If RC is unreachable the datasource will throw and the app will show
  //     its normal error state rather than using a hardcoded fallback URL.
  static const _defaultJson = '''
{
  "skip_onboarding": false,
  "skip_tour": false,
  "premium": false,
  "spin_always_ready": false,
  "show_wallet": true,
  "show_live_feed_button": true,
  "live_feed_title": "Live Feed",
  "api_base_url": "",
  "api_m_base_url": "",
  "api_crex_url": "",
  "ipl_schedule_series_id": "9241",
  "under_maintenance": false,
  "min_app_version": "1.0.0+15",
  "force_update": false
}
''';

  static const _defaultAdJson = '''
{
  "interstitial_id": "ca-app-pub-2689108233364143/8904121718",
  "rewarded_id": "ca-app-pub-2689108233364143/7404739185",
  "banner_id": "ca-app-pub-2689108233364143/7607218464",
  "app_open_id": "ca-app-pub-2689108233364143/4733643114",
  "interstitial_every": 4,
  "premium_promo_every": 6
}
''';

  Map<String, dynamic> _flags = {};
  Map<String, dynamic> _ads = {};

  /// Full init — fetches latest values from Firebase.
  /// Call this when device is online.
  Future<void> init() async {
    _rc = FirebaseRemoteConfig.instance;

    await _rc.setDefaults({
      kAppConfig: _defaultJson,
      kAdConfig: _defaultAdJson,
    });

    await _rc.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode
            ? Duration.zero
            : const Duration(hours: 1),
      ),
    );

    try {
      await _rc.fetchAndActivate();
    } catch (e) {
      debugPrint('⚠️ RemoteConfig fetch failed (using defaults): $e');
    }

    _parseFlags();
    _parseAds();
  }

  /// Offline init — skips network fetch, uses last cached or default values.
  /// Call this when device has no internet so main() doesn't hang.
  Future<void> initOffline() async {
    _rc = FirebaseRemoteConfig.instance;
    await _rc.setDefaults({
      kAppConfig: _defaultJson,
      kAdConfig: _defaultAdJson,
    });
    // activate() uses whatever is already cached locally (no network call)
    await _rc.activate();
    _parseFlags();
    _parseAds();
    debugPrint('ℹ️ RemoteConfig: offline init — using cached/default values');
  }

  void _parseFlags() {
    try {
      final defaults =
          json.decode(_defaultJson) as Map<String, dynamic>;
      final raw = _rc.getString(kAppConfig);
      final fetched =
          json.decode(raw.isEmpty ? _defaultJson : raw) as Map<String, dynamic>;
      // Merge: defaults first, fetched values override.
      // This ensures new keys added in _defaultJson work even before
      // they are added to Firebase Console.
      _flags = {...defaults, ...fetched};
    } catch (e) {
      debugPrint('⚠️ RemoteConfig parse failed (using defaults): $e');
      _flags = json.decode(_defaultJson) as Map<String, dynamic>;
    }
  }

  void _parseAds() {
    try {
      final raw = _rc.getString(kAdConfig);
      _ads =
          json.decode(raw.isEmpty ? _defaultAdJson : raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('⚠️ RemoteConfig Ads parse failed (using defaults): $e');
      _ads = json.decode(_defaultAdJson) as Map<String, dynamic>;
    }
  }

  bool _flag(String key, bool fallback) => _flags[key] as bool? ?? fallback;
  String _str(String key) => (_flags[key] as String? ?? '').trim();

  // ── Dev flag getters ──────────────────────────────────────────────────────
  bool get devSkipOnboarding => _flag('skip_onboarding', false);
  bool get devSkipAppTour => _flag('skip_tour', false);
  bool get devPremiumOverride => _flag('premium', false);
  bool get devForceSpinAvailable => _flag('spin_always_ready', false);
  bool get devShowWalletUI => _flag('show_wallet', true);
  bool get devShowLiveFeedButton => _flag('show_live_feed_button', true);
  bool get underMaintenance => _flag('under_maintenance', false);
  bool get forceUpdate => _flag('force_update', false);
  String get minAppVersion => _str('min_app_version');

  String get liveFeedTitle => _str('live_feed_title');

  String get apiBaseUrl => _str('api_base_url');

  String get apiMBaseUrl => _str('api_m_base_url');

  String get apiCrexUrl => _str('api_crex_url');

  String get iplScheduleSeriesId => _str('ipl_schedule_series_id');

  // ── Ad Unit ID getters ────────────────────────────────────────────────────
  String get adInterstitialId => (_ads['interstitial_id'] as String? ?? '').trim();
  String get adRewardedId => (_ads['rewarded_id'] as String? ?? '').trim();
  String get adBannerId => (_ads['banner_id'] as String? ?? '').trim();
  String get adAppOpenId => (_ads['app_open_id'] as String? ?? '').trim();

  int get adInterstitialEvery => _ads['interstitial_every'] as int? ?? 4;
  int get adPremiumPromoEvery => _ads['premium_promo_every'] as int? ?? 6;
}
