import 'package:cricketbuzz/features/auth/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Future<AppUser> signInWithGoogle();
  Future<AppUser> signInAsGuest(String name);
  Future<void> signOut();
  Future<AppUser?> getCurrentUser();
  Future<void> updateUser(AppUser user);
}
