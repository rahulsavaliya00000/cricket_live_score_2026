import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cricket_live_score/core/di/injection_container.dart';

/// Thin wrapper around [FirebaseAnalytics].
///
/// Usage from anywhere:
///   AnalyticsService.instance.logSpinWheelResult(rewardType: 'coins', amount: 50);
///
/// All methods are fire-and-forget (no await needed at call sites).
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// The observer to pass to MaterialApp.router → enables automatic
  /// screen_view events for every GoRouter navigation.
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ── App lifecycle ─────────────────────────────────────────────────────────

  /// Logs a one-time 'app_install' event when the app is first opened.
  Future<void> logAppInstall() async {
    final prefs = sl<SharedPreferences>();
    const key = 'has_sent_install_event';
    
    if (prefs.getBool(key) ?? false) return;

    await _log(() => _analytics.logEvent(name: 'app_install'));
    await prefs.setBool(key, true);
    debugPrint('🚀 Analytics: app_install event sent (first-time only)');
  }

  Future<void> logAppOpen() => _log(() => _analytics.logAppOpen());

  // ── Auth ──────────────────────────────────────────────────────────────────

  /// [method]: 'google', 'guest'
  Future<void> logLogin({required String method}) =>
      _log(() => _analytics.logLogin(loginMethod: method));

  Future<void> logSignUp({required String method}) =>
      _log(() => _analytics.logSignUp(signUpMethod: method));

  Future<void> logLogout() => _log(() => _analytics.logEvent(name: 'logout'));

  // ── Onboarding ────────────────────────────────────────────────────────────

  Future<void> logOnboardingComplete() =>
      _log(() => _analytics.logTutorialComplete());

  Future<void> logOnboardingSkipped() =>
      _log(() => _analytics.logEvent(name: 'onboarding_skipped'));

  // ── Spin Wheel ────────────────────────────────────────────────────────────

  Future<void> logSpinWheelOpened() =>
      _log(() => _analytics.logEvent(name: 'spin_wheel_opened'));

  /// [rewardType]: 'coins', 'balls', 'bats'
  /// [amount]: quantity won
  Future<void> logSpinWheelResult({
    required String rewardType,
    required int amount,
  }) => _log(
    () => _analytics.logEarnVirtualCurrency(
      virtualCurrencyName: rewardType,
      value: amount.toDouble(),
    ),
  );

  Future<void> logSpinWheelCooldown() =>
      _log(() => _analytics.logEvent(name: 'spin_wheel_on_cooldown'));

  // ── Premium ───────────────────────────────────────────────────────────────

  Future<void> logPremiumPageOpened() =>
      _log(() => _analytics.logEvent(name: 'premium_page_opened'));

  Future<void> logPremiumPurchased({required String packageId}) => _log(
    () => _analytics.logPurchase(
      currency: 'USD',
      value: 0, // actual value logged by RevenueCat — this is supplemental
      items: [AnalyticsEventItem(itemId: packageId, itemName: 'Premium')],
    ),
  );

  Future<void> logPremiumRestored() =>
      _log(() => _analytics.logEvent(name: 'premium_restored'));

  // ── Matches & Content ─────────────────────────────────────────────────────

  Future<void> logMatchOpened({required String matchId}) => _log(
    () => _analytics.logSelectContent(contentType: 'match', itemId: matchId),
  );

  Future<void> logPlayerOpened({required String playerId}) => _log(
    () => _analytics.logSelectContent(contentType: 'player', itemId: playerId),
  );

  Future<void> logSeriesOpened({required String seriesId}) => _log(
    () => _analytics.logSelectContent(contentType: 'series', itemId: seriesId),
  );

  // ── Ads ───────────────────────────────────────────────────────────────────

  Future<void> logAdShown({required String adType}) => _log(
    () =>
        _analytics.logEvent(name: 'ad_shown', parameters: {'ad_type': adType}),
  );

  Future<void> logAdFreePurchased() =>
      _log(() => _analytics.logEvent(name: 'ad_free_purchased'));

  // ── Notifications ─────────────────────────────────────────────────────────

  Future<void> logNotificationTapped({required String route}) => _log(
    () => _analytics.logEvent(
      name: 'notification_tapped',
      parameters: {'route': route},
    ),
  );

  // ── User properties ───────────────────────────────────────────────────────

  Future<void> setUserPremium(bool isPremium) => _log(
    () => _analytics.setUserProperty(
      name: 'is_premium',
      value: isPremium ? 'true' : 'false',
    ),
  );

  Future<void> setUserId(String? uid) =>
      _log(() => _analytics.setUserId(id: uid));

  // ── Screen ────────────────────────────────────────────────────────────────

  Future<void> logScreenView({required String screenName}) =>
      _log(() => _analytics.logScreenView(screenName: screenName));

  // ── Internal helper ───────────────────────────────────────────────────────

  Future<void> _log(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (e) {
      debugPrint('⚠️ Analytics error: $e');
    }
  }
}
