import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cricket_live_score/core/constants/app_constants.dart';
import 'package:cricket_live_score/core/error/exceptions.dart';
import 'package:cricket_live_score/features/auth/data/models/user_model.dart';
import 'package:cricket_live_score/features/auth/domain/entities/user_entity.dart';

abstract class AuthDataSource {
  Future<UserModel> signInWithGoogle();
  Future<UserModel> signInAsGuest(String name);
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Future<void> saveUserToFirestore(UserModel user);
  Future<UserModel?> getUserFromFirestore(String uid);
  Future<void> updateUserInFirestore(UserModel user);
}

class AuthDataSourceImpl implements AuthDataSource {
  final FirebaseAuth firebaseAuth;
  final GoogleSignIn googleSignIn;
  final FirebaseFirestore firestore;

  AuthDataSourceImpl({
    required this.firebaseAuth,
    required this.googleSignIn,
    required this.firestore,
  });

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      debugPrint('🔑 [AUTH_DATASOURCE] signInWithGoogle() started...');
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('⚠️ [AUTH_DATASOURCE] Google Sign In cancelled by user');
        throw AuthException('Google sign in cancelled');
      }

      debugPrint('📡 [AUTH_DATASOURCE] Google User: ${googleUser.email}');
      final googleAuth = await googleUser.authentication;
      debugPrint('🎫 [AUTH_DATASOURCE] Tokens received (idToken: ${googleAuth.idToken != null})');
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('🔥 [AUTH_DATASOURCE] Signing in to Firebase with credential...');
      final userCredential = await firebaseAuth.signInWithCredential(
        credential,
      );
      final user = userCredential.user!;
      debugPrint('✅ [AUTH_DATASOURCE] Firebase Auth SUCCESS: uid=${user.uid}');

      // Check if user already exists in Firestore
      debugPrint('🔍 [AUTH_DATASOURCE] Checking Firestore for user: ${user.uid}');
      final existingUser = await getUserFromFirestore(user.uid);
      if (existingUser != null) {
        debugPrint('💼 [AUTH_DATASOURCE] Existing user found in Firestore');
        return existingUser;
      }

      debugPrint('➕ [AUTH_DATASOURCE] New user! Creating record in Firestore...');
      final newUser = UserModel(
        uid: user.uid,
        name: user.displayName ?? 'Cricket Fan',
        email: user.email,
        photoUrl: user.photoURL,
        authType: AuthType.google,
        createdAt: DateTime.now(),
      );

      await saveUserToFirestore(newUser);
      debugPrint('✨ [AUTH_DATASOURCE] Firestore record created successfully');
      return newUser;
    } on AuthException catch (e) {
      debugPrint('❌ [AUTH_DATASOURCE] AuthException: ${e.message}');
      rethrow;
    } catch (e, stack) {
      debugPrint('💥 [AUTH_DATASOURCE] CRITICAL ERROR during Google Sign In: $e\n$stack');
      throw AuthException('Google sign in failed: $e');
    }
  }

  @override
  Future<UserModel> signInAsGuest(String name) async {
    try {
      final userCredential = await firebaseAuth.signInAnonymously();
      final user = userCredential.user!;

      final newUser = UserModel(
        uid: user.uid,
        name: name.trim().isEmpty ? 'Cricket Fan' : name.trim(),
        authType: AuthType.guest,
        createdAt: DateTime.now(),
      );

      await saveUserToFirestore(newUser);
      return newUser;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'admin-restricted-operation' ||
          e.code == 'operation-not-allowed') {
        throw AuthException(
          'Guest login is disabled. Please enable "Anonymous" in Firebase Console.',
        );
      }
      throw AuthException(e.message ?? 'Guest sign in failed');
    } catch (e) {
      throw AuthException('Guest sign in failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await Future.wait([firebaseAuth.signOut(), googleSignIn.signOut()]);
    } catch (e) {
      throw AuthException('Sign out failed: $e');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = firebaseAuth.currentUser;
    if (user == null) return null;
    return getUserFromFirestore(user.uid);
  }

  @override
  Future<void> saveUserToFirestore(UserModel user) async {
    try {
      await firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .set(user.toFirestore());
    } catch (e) {
      throw AuthException('Failed to save user: $e');
    }
  }

  @override
  Future<UserModel?> getUserFromFirestore(String uid) async {
    try {
      final doc = await firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw AuthException('Failed to get user: $e');
    }
  }

  @override
  Future<void> updateUserInFirestore(UserModel user) async {
    try {
      await firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .update(user.toFirestore());
    } catch (e) {
      throw AuthException('Failed to update user: $e');
    }
  }
}
