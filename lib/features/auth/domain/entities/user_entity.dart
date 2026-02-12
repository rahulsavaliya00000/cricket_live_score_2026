import 'package:equatable/equatable.dart';

enum AuthType { google, guest }

class AppUser extends Equatable {
  final String uid;
  final String name;
  final String? email;
  final String? photoUrl;
  final AuthType authType;
  final DateTime createdAt;
  final String preferredLanguage;
  final String themePreference;
  final NotificationPreferences notificationPrefs;

  const AppUser({
    required this.uid,
    required this.name,
    this.email,
    this.photoUrl,
    required this.authType,
    required this.createdAt,
    this.preferredLanguage = 'en',
    this.themePreference = 'dark',
    this.notificationPrefs = const NotificationPreferences(),
  });

  AppUser copyWith({
    String? name,
    String? email,
    String? photoUrl,
    String? preferredLanguage,
    String? themePreference,
    NotificationPreferences? notificationPrefs,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      authType: authType,
      createdAt: createdAt,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      themePreference: themePreference ?? this.themePreference,
      notificationPrefs: notificationPrefs ?? this.notificationPrefs,
    );
  }

  @override
  List<Object?> get props => [uid];
}

class NotificationPreferences extends Equatable {
  final bool matchStart;
  final bool wickets;
  final bool results;
  final List<String> favoriteTeams;

  const NotificationPreferences({
    this.matchStart = true,
    this.wickets = true,
    this.results = true,
    this.favoriteTeams = const [],
  });

  NotificationPreferences copyWith({
    bool? matchStart,
    bool? wickets,
    bool? results,
    List<String>? favoriteTeams,
  }) {
    return NotificationPreferences(
      matchStart: matchStart ?? this.matchStart,
      wickets: wickets ?? this.wickets,
      results: results ?? this.results,
      favoriteTeams: favoriteTeams ?? this.favoriteTeams,
    );
  }

  Map<String, dynamic> toMap() => {
    'matchStart': matchStart,
    'wickets': wickets,
    'results': results,
    'favoriteTeams': favoriteTeams,
  };

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      matchStart: map['matchStart'] ?? true,
      wickets: map['wickets'] ?? true,
      results: map['results'] ?? true,
      favoriteTeams: List<String>.from(map['favoriteTeams'] ?? []),
    );
  }

  @override
  List<Object?> get props => [matchStart, wickets, results, favoriteTeams];
}
