import 'package:cricketbuzz/features/auth/data/datasources/auth_datasource.dart';
import 'package:cricketbuzz/features/auth/data/models/user_model.dart';
import 'package:cricketbuzz/features/auth/domain/entities/user_entity.dart';
import 'package:cricketbuzz/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource dataSource;

  AuthRepositoryImpl({required this.dataSource});

  @override
  Future<AppUser> signInWithGoogle() => dataSource.signInWithGoogle();

  @override
  Future<AppUser> signInAsGuest(String name) => dataSource.signInAsGuest(name);

  @override
  Future<void> signOut() => dataSource.signOut();

  @override
  Future<AppUser?> getCurrentUser() => dataSource.getCurrentUser();

  @override
  Future<void> updateUser(AppUser user) =>
      dataSource.updateUserInFirestore(UserModel.fromEntity(user));
}
