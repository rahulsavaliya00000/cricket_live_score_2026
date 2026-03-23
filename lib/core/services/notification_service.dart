import 'dart:math';
import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cricket_live_score/core/router/app_router.dart';

// ─── Native navigation channel (used by NotificationActionReceiver.kt) ───────
const MethodChannel _navChannel = MethodChannel(
  'com.qdevix.cricket_live_score_2026/navigation',
);

// ─── Native notification channel (custom RemoteViews notification) ───────────
const MethodChannel _notifChannel = MethodChannel(
  'com.qdevix.cricket_live_score_2026/notification',
);

/// Background notification tap handler — must be a top-level function.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse details) {
  // Background taps are handled when the app resumes via onDidReceiveNotificationResponse.
  // No navigation here since no BuildContext is available.
  debugPrint('🔔 Background notification action: ${details.actionId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Set this from main.dart so tapping a notification can navigate
  static GlobalKey<NavigatorState>? navigatorKey;

  static const String _enabledKey = 'notifications_enabled';
  static const int _dailyNotifId = 100;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final _random = Random();

  // Cricket-themed notification messages
  static const List<Map<String, String>> _messages = [
    {
      'title': 'Live Cricket Action! 🏏',
      'body': 'Matches are on today! Check those live scores.',
    },
    {
      'title': 'Game On! 🏟️',
      'body': 'Don\'t miss today\'s matches — open the app for live updates.',
    },
    {
      'title': 'Cricket Time! 🔥',
      'body': 'Your favourite teams might be playing right now. Take a look!',
    },
    {
      'title': 'Scorecard Update 📊',
      'body': 'Matches are waiting for you. Tap to check live scores!',
    },
    {
      'title': 'It\'s Match Day! 🎯',
      'body': 'Cricket is happening — catch every ball, run, and wicket.',
    },
    {
      'title': 'Stumps or Sixes? 🏏',
      'body': 'Exciting matches today! See what\'s happening on the pitch.',
    },
    {
      'title': 'Howzat! 🙌',
      'body': 'Live cricket is on. Don\'t let a great match slip by.',
    },
    {
      'title': 'Boundary Alert! 💥',
      'body': 'Today\'s cricket action awaits. Open for live scores.',
    },
  ];

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@drawable/ic_notif');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        if (details.payload == 'free_spin') {
          final ctx =
              rootNavigatorKey.currentContext ?? navigatorKey?.currentContext;
          if (ctx == null) return;
          if (details.actionId == 'live_score') {
            // ignore: use_build_context_synchronously
            GoRouter.of(ctx).go('/');
          } else {
            // 'spin_now' button OR tapping the notification body
            // ignore: use_build_context_synchronously
            GoRouter.of(ctx).go('/spin-wheel');
          }
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Create channels for Android
    const AndroidNotificationChannel dailyChannel = AndroidNotificationChannel(
      'daily_match_alerts',
      'Daily Match Alerts',
      description: 'Receive daily updates about live cricket matches',
      importance: Importance.max,
    );

    const AndroidNotificationChannel spinChannel = AndroidNotificationChannel(
      'free_spin_reminder',
      'Free Spin Reminder',
      description: 'Get notified when your daily free spin is ready',
      importance: Importance.max,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(dailyChannel);
    await androidPlugin?.createNotificationChannel(spinChannel);

    // ── Listen for navigation from NotificationActionReceiver when app is OPEN ──
    // This handles the case where app is fully open (foreground).
    // Background/killed start is handled by navigateFromLaunch() via SharedPreferences.
    _navChannel.setMethodCallHandler((call) async {
      if (call.method == 'navigate') {
        final route = call.arguments as String?;
        if (route == null) return;
        _navigateNow(route);
      }
    });
  }

  /// Called from initState's postFrameCallback — reads the pending route
  /// directly from SharedPreferences (written by Kotlin before startActivity).
  /// No MethodChannel needed — works for all states: killed, background, open.
  Future<void> navigateFromLaunch() async {
    if (!Platform.isAndroid) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      // Force a fresh read from disk (not the in-memory cache)
      await prefs.reload();
      final route = prefs.getString('pending_notification_route');
      if (route == null || route.isEmpty) return;
      // Clear it immediately so it doesn't replay on next launch
      await prefs.remove('pending_notification_route');
      debugPrint('🔔 navigateFromLaunch: $route');
      _navigateNow(route);
    } catch (e) {
      debugPrint('⚠️ navigateFromLaunch error: $e');
    }
  }

  /// Navigates immediately — only call when rootNavigatorKey.currentContext is ready.
  void _navigateNow(String route) {
    final ctx = rootNavigatorKey.currentContext ?? navigatorKey?.currentContext;
    if (ctx == null) {
      debugPrint('⚠️ _navigateNow: no context for $route');
      return;
    }
    try {
      GoRouter.of(ctx).go(route);
      debugPrint('✅ Navigated to $route');
    } catch (e) {
      debugPrint('⚠️ Navigate error: $e');
    }
  }

  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  /// Requests permissions and returns whether they were granted.
  Future<bool> requestAndCheckPermissions() async {
    // Request first
    await requestPermissions();

    // Check if actually granted
    if (Platform.isIOS) {
      final iosPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
    } else if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        final granted = await androidPlugin.areNotificationsEnabled();
        return granted ?? false;
      }
    }
    return true; // Default to true for other platforms
  }

  /// Opens the app's notification settings page in the OS.
  Future<void> openAppSettings() async {
    if (Platform.isIOS) {
      // Opens the app settings page on iOS
      const channel = MethodChannel('app_settings');
      try {
        await channel.invokeMethod('openSettings');
      } catch (_) {
        // Fallback: use the notification plugin's built-in method if available
        debugPrint('Could not open app settings via MethodChannel');
      }
    } else if (Platform.isAndroid) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidPlugin?.requestNotificationsPermission();
    }
  }

  static const String _prefMatchStart = 'pref_match_start';
  static const String _prefWicket = 'pref_wicket';
  static const String _prefResult = 'pref_result';

  // ─── Notification Toggle ────────────────────────────────────────

  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true; // enabled by default
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);

    if (enabled) {
      await scheduleDailyNotification();
    } else {
      await cancelDailyNotification();
    }
  }

  // ─── Granular Preferences ───────────────────────────────────────

  Future<Map<String, bool>> getPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'matchStart': prefs.getBool(_prefMatchStart) ?? true,
      'wicket': prefs.getBool(_prefWicket) ?? true,
      'result': prefs.getBool(_prefResult) ?? true,
    };
  }

  Future<void> setPreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    String? prefKey;
    if (key == 'matchStart') prefKey = _prefMatchStart;
    if (key == 'wicket') prefKey = _prefWicket;
    if (key == 'result') prefKey = _prefResult;

    if (prefKey != null) {
      await prefs.setBool(prefKey, value);
    }
  }

  // ─── Scheduling ─────────────────────────────────────────────────

  Future<void> scheduleDailyNotification() async {
    try {
      // Check if notifications are enabled
      final enabled = await isEnabled();
      if (!enabled) return;

      // Cancel existing to avoid duplicates
      await _plugin.cancel(id: _dailyNotifId);

      // Pick a random message
      final msg = _messages[_random.nextInt(_messages.length)];

      // Schedule at a random time between 8 AM and 10 PM (not midnight!)
      final scheduledDate = _nextRandomDaytime();

      await _plugin.zonedSchedule(
        id: _dailyNotifId,
        title: msg['title'],
        body: msg['body'],
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_match_alerts',
            'Daily Match Alerts',
            channelDescription: 'Daily updates for cricket matches',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@drawable/ic_notif',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      debugPrint(
        '📅 Notification scheduled for ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')}',
      );
    } catch (e) {
      debugPrint('❌ Error scheduling notification: $e');
    }
  }

  Future<void> cancelDailyNotification() async {
    await _plugin.cancel(id: _dailyNotifId);
    debugPrint('🔕 Daily notification cancelled');
  }

  /// Returns a TZDateTime for a random time between 8:00 AM and 9:59 PM
  /// today (or tomorrow if the chosen time has already passed).
  tz.TZDateTime _nextRandomDaytime() {
    final now = tz.TZDateTime.now(tz.local);

    // Random hour: 8 to 21 (8 AM to 9 PM) — notification won't fire after 10 PM
    final hour = 8 + _random.nextInt(14); // 8..21
    final minute = _random.nextInt(60);

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If chosen time already passed today, schedule for tomorrow
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  /// Returns a TZDateTime for tomorrow morning between 8:00 AM and 11:00 AM.
  /// Used to remind the user their free spin has reset overnight.
  tz.TZDateTime _tomorrowMorning() {
    final now = tz.TZDateTime.now(tz.local);
    final hour = 8 + _random.nextInt(4); // 8, 9, 10, or 11 AM
    final minute = _random.nextInt(60);
    // Always tomorrow — regardless of current time
    return tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + 1,
      hour,
      minute,
    );
  }

  // ─── Free Spin Sticky Notification ──────────────────────────

  static const int _spinNotifId = 200;

  /// Returns a different title every calendar day (cycles through 8 messages).
  /// Uses day-of-year so it changes at midnight without any storage.
  static const List<String> _spinTitles = [
    '🎁 Free Daily Spin Available!',
    '🎰 Your Spin Wheel is Ready!',
    '🔥 Claim Your Free Spin Today!',
    '🌀 Daily Spin Unlocked — Play Now!',
    '✨ Lucky Spin Waiting for You!',
    '🏏 Win Coins & Balls — Spin Now!',
    '🎯 Don\'t Miss Your Free Daily Spin!',
    '🎊 Free Spin Just Reset — Go Win!',
  ];

  String _dailySpinTitle() {
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    return _spinTitles[dayOfYear % _spinTitles.length];
  }

  /// App theme primary green — used as the notification accent color.
  static const int _spinColor = 0xFF00A86B; // primaryGreen

  /// Returns the app's primary green color (constant, never rotates).
  Color _dailySpinColor() => const Color(_spinColor);

  Future<void> showStickySpinNotification() async {
    // ── Android: use native RemoteViews notification with real styled buttons ──
    if (Platform.isAndroid) {
      try {
        await _notifChannel.invokeMethod('showSpinNotification', {
          'title': _dailySpinTitle(),
          'body': 'Tap Spin Now to win coins, balls & bats!',
          'color': _dailySpinColor().toARGB32(),
        });
        return;
      } catch (e) {
        debugPrint('⚠️ Native notification failed, falling back: $e');
      }
    }

    // ── iOS (or Android fallback): flutter_local_notifications ────────────────
    final tickers = [
      '🎁 Free spin available — claim it now!',
      '🔥 Your daily spin is waiting!',
      '🌀 Spin the wheel & win rewards!',
      '✨ Lucky spin ready — don\'t miss it!',
    ];
    final ticker = tickers[_random.nextInt(tickers.length)];

    final androidDetails = AndroidNotificationDetails(
      'free_spin_reminder',
      'Free Spin Reminder',
      channelDescription: 'Get notified when your daily free spin is ready',
      importance: Importance.max,
      priority: Priority.high,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      ticker: ticker,
      color: _dailySpinColor(),
      styleInformation: BigTextStyleInformation(
        '✨ Tap to spin the wheel and win coins, balls & bats!',
        htmlFormatBigText: false,
        contentTitle: _dailySpinTitle(),
        htmlFormatContentTitle: false,
        summaryText: '🏏 Cricket Live Score',
      ),
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'spin_now',
          '🎰 Spin Now',
          showsUserInterface: true,
          cancelNotification: false,
        ),
        AndroidNotificationAction(
          'live_score',
          '🔴 Live Match',
          showsUserInterface: true,
          cancelNotification: false,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
      interruptionLevel: InterruptionLevel.passive,
      subtitle: 'Tap to claim your free daily spin!',
    );

    await _plugin.show(
      id: _spinNotifId,
      title: _dailySpinTitle(),
      body: '✨ Tap to spin the wheel and win coins, balls & bats!',
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: 'free_spin',
    );
  }

  Future<void> cancelSpinNotification() async {
    if (Platform.isAndroid) {
      try {
        await _notifChannel.invokeMethod('cancelSpinNotification');
        return;
      } catch (_) {}
    }
    await _plugin.cancel(id: _spinNotifId);
  }

  /// Called when the app is backgrounded. Schedules a notification for
  /// tomorrow morning so the user is reminded their free spin has reset,
  /// even if they never reopen the app that day.
  Future<void> scheduleSpinReminder() async {
    final scheduledDate = _tomorrowMorning();

    // NOTE: This is a scheduled (one-shot) alert — NOT ongoing.
    // When the user taps it, the app opens and _onAppResumed / initState
    // will call showStickySpinNotification() to post the real sticky then.
    final androidDetails = AndroidNotificationDetails(
      'free_spin_reminder',
      'Free Spin Reminder',
      channelDescription: 'Get notified when your daily free spin is ready',
      importance: Importance.max,
      priority: Priority.high,
      ongoing:
          false, // must be false — Android ignores ongoing on scheduled notifs
      autoCancel: true, // dismisses itself when tapped
      ticker: '🔥 Your free spin just reset — come claim it!',
      color: _dailySpinColor(),
      styleInformation: BigTextStyleInformation(
        '🎰 Your free spin has reset — tap to claim it now!',
        htmlFormatBigText: false,
        contentTitle: _dailySpinTitle(),
        htmlFormatContentTitle: false,
        summaryText: '🏏 Cricket Live Score',
      ),
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'spin_now',
          '🎰 Spin Now',
          showsUserInterface: true,
          cancelNotification: true, // dismiss this alert notif on tap
        ),
        AndroidNotificationAction(
          'live_score',
          '🔴 Live Match',
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
      subtitle: 'Your free daily spin has reset — claim it!',
    );

    try {
      await _plugin.zonedSchedule(
        id: _spinNotifId,
        title: _dailySpinTitle(),
        body: '🎰 Your free spin has reset — tap to claim it now!',
        scheduledDate: scheduledDate,
        notificationDetails: NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'free_spin',
      );
      debugPrint(
        '🎰 Spin Reminder scheduled for ${scheduledDate.hour}:${scheduledDate.minute.toString().padLeft(2, '0')}',
      );
    } catch (e) {
      debugPrint('❌ Error scheduling spin reminder: $e');
    }
  }
}
