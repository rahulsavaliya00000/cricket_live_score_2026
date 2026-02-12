import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cricketbuzz/core/constants/app_constants.dart';
import 'package:cricketbuzz/core/error/exceptions.dart';
import 'package:cricketbuzz/features/auth/data/models/user_model.dart';
import 'package:cricketbuzz/features/auth/domain/entities/user_entity.dart';

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
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) throw AuthException('Google sign in cancelled');

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await firebaseAuth.signInWithCredential(
        credential,
      );
      final user = userCredential.user!;

      // Check if user already exists in Firestore
      final existingUser = await getUserFromFirestore(user.uid);
      if (existingUser != null) return existingUser;

      final newUser = UserModel(
        uid: user.uid,
        name: user.displayName ?? 'Cricket Fan',
        email: user.email,
        photoUrl: user.photoURL,
        authType: AuthType.google,
        createdAt: DateTime.now(),
      );

      await saveUserToFirestore(newUser);
      return newUser;
    } on AuthException {
      rethrow;
    } catch (e) {
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
