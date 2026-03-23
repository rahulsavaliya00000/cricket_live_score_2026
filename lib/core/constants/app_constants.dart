// App-wide constants
import 'package:cricketbuzz/core/services/remote_config_service.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'CricketBuzz';
  static const String appVersion = '1.0.0+15';

  // Cache durations
  static const Duration liveCacheDuration = Duration(seconds: 30);
  static const Duration matchListCacheDuration = Duration(minutes: 5);
  static const Duration playerCacheDuration = Duration(hours: 1);

  // Firestore collections
  static const String usersCollection = 'users';

  // SharedPreferences keys
  static const String themeKey = 'theme_preference';
  static const String languageKey = 'language_preference';
  static const String firstLaunchKey = 'first_launch';
  static const String hasSeenOnboardingKey = 'has_seen_onboarding';
  static const String hasSeenAppTourKey = 'has_seen_app_tour';
  static const String pipTrialDateKey =
      'pip_trial_date'; // stores ISO date string of when trial was activated

  // ═══════════════════════════════════════════════════════════════════════════
  // ███  DEV FLAGS — controlled via Firebase Remote Config at runtime  ███
  // ███  Falls back to these defaults when Remote Config is unavailable  ███
  // ═══════════════════════════════════════════════════════════════════════════

  /// true  → skips onboarding screen, goes straight to /home
  static bool get devSkipOnboarding =>
      RemoteConfigService.instance.devSkipOnboarding;

  /// true  → skips the app-tour coach-marks on home screen
  static bool get devSkipAppTour => RemoteConfigService.instance.devSkipAppTour;

  /// true  → force-unlocks premium without a real RevenueCat purchase
  static bool get devPremiumOverride =>
      RemoteConfigService.instance.devPremiumOverride;
  // static bool get devPremiumOverride => true;

  /// true  → wallet always shows canSpinFree = true (spin wheel always ready)
  static bool get devForceSpinAvailable =>
      RemoteConfigService.instance.devForceSpinAvailable;

  /// true  → shows WalletChip & Spin FAB on home screen
  static bool get devShowWalletUI =>
      RemoteConfigService.instance.devShowWalletUI;

  /// Min required version + force update flag from Remote Config
  static String get minAppVersion => RemoteConfigService.instance.minAppVersion;
  static bool get forceUpdate => RemoteConfigService.instance.forceUpdate;

  // ═══════════════════════════════════════════════════════════════════════════

  /// true -> shows the Ad Inspector FAB on the home screen
  static const bool showAdInspector = false;
}
