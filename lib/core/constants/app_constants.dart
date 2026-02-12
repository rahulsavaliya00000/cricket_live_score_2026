// App-wide constants
class AppConstants {
  AppConstants._();

  static const String appName = 'CricketBuzz';
  static const String appVersion = '1.0.0';

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

  // Ad unit IDs (test IDs — replace with real ones)
  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String nativeAdUnitId = 'ca-app-pub-3940256099942544/2247696110';
}
