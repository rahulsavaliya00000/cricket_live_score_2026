import 'dart:math';
import 'dart:io' show Platform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

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
        AndroidInitializationSettings('@mipmap/ic_launcher');

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
        // Handle notification tap — nothing needed for now
      },
    );

    // Create channel for Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'daily_match_alerts',
      'Daily Match Alerts',
      description: 'Receive daily updates about live cricket matches',
      importance: Importance.max,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
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
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
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
}
