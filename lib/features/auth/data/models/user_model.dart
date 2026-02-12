import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cricketbuzz/features/auth/domain/entities/user_entity.dart';

class UserModel extends AppUser {
  const UserModel({
    required super.uid,
    required super.name,
    super.email,
    super.photoUrl,
    required super.authType,
    required super.createdAt,
    super.preferredLanguage,
    super.themePreference,
    super.notificationPrefs,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'],
      photoUrl: data['photoUrl'],
      authType: data['authType'] == 'google' ? AuthType.google : AuthType.guest,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      preferredLanguage: data['preferredLanguage'] ?? 'en',
      themePreference: data['themePreference'] ?? 'dark',
      notificationPrefs: data['notificationPreferences'] != null
          ? NotificationPreferences.fromMap(
              Map<String, dynamic>.from(data['notificationPreferences']),
            )
          : const NotificationPreferences(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'authType': authType == AuthType.google ? 'google' : 'guest',
      'createdAt': Timestamp.fromDate(createdAt),
      'preferredLanguage': preferredLanguage,
      'themePreference': themePreference,
      'notificationPreferences': notificationPrefs.toMap(),
    };
  }

  factory UserModel.fromEntity(AppUser user) {
    return UserModel(
      uid: user.uid,
      name: user.name,
      email: user.email,
      photoUrl: user.photoUrl,
      authType: user.authType,
      createdAt: user.createdAt,
      preferredLanguage: user.preferredLanguage,
      themePreference: user.themePreference,
      notificationPrefs: user.notificationPrefs,
    );
  }
}
