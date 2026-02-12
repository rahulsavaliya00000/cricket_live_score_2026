import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cricketbuzz/features/auth/domain/entities/user_entity.dart';
import 'package:cricketbuzz/features/auth/domain/repositories/auth_repository.dart';

// ─── Events ──────────────────────────────────────────────
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {}

class SignInWithGoogle extends AuthEvent {}

class SignInAsGuest extends AuthEvent {
  final String name;
  SignInAsGuest(this.name);
  @override
  List<Object?> get props => [name];
}

class SignOutRequested extends AuthEvent {}

class UpdateUserProfile extends AuthEvent {
  final AppUser user;
  UpdateUserProfile(this.user);
  @override
  List<Object?> get props => [user];
}

// ─── States ──────────────────────────────────────────────
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final AppUser user;
  Authenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ────────────────────────────────────────────────
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository repository;

  AuthBloc({required this.repository}) : super(AuthInitial()) {
    on<CheckAuthStatus>(_onCheckAuth);
    on<SignInWithGoogle>(_onGoogleSignIn);
    on<SignInAsGuest>(_onGuestSignIn);
    on<SignOutRequested>(_onSignOut);
    on<UpdateUserProfile>(_onUpdateProfile);
  }

  Future<void> _onCheckAuth(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await repository.getCurrentUser();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(Unauthenticated());
      }
    } catch (e) {
      emit(Unauthenticated());
    }
  }

  Future<void> _onGoogleSignIn(
    SignInWithGoogle event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await repository.signInWithGoogle();
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onGuestSignIn(
    SignInAsGuest event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final user = await repository.signInAsGuest(event.name);
      emit(Authenticated(user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignOut(
    SignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await repository.signOut();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateUserProfile event,
    Emitter<AuthState> emit,
  ) async {
    try {
      await repository.updateUser(event.user);
      emit(Authenticated(event.user));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
