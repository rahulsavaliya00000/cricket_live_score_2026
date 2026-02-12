import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cricketbuzz/core/constants/app_constants.dart';

// ─── Events ──────────────────────────────────────────────
abstract class ThemeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadTheme extends ThemeEvent {}

class ToggleTheme extends ThemeEvent {}

class SetThemeMode extends ThemeEvent {
  final ThemeMode themeMode;
  SetThemeMode(this.themeMode);

  @override
  List<Object?> get props => [themeMode];
}

class ChangeLocale extends ThemeEvent {
  final Locale locale;
  ChangeLocale(this.locale);

  @override
  List<Object?> get props => [locale];
}

// ─── State ───────────────────────────────────────────────
class ThemeState extends Equatable {
  final ThemeMode themeMode;
  final Locale locale;

  const ThemeState({
    this.themeMode = ThemeMode.dark,
    this.locale = const Locale('en'),
  });

  ThemeState copyWith({ThemeMode? themeMode, Locale? locale}) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }

  @override
  List<Object?> get props => [themeMode, locale];
}

// ─── BLoC ────────────────────────────────────────────────
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final SharedPreferences prefs;

  ThemeBloc({required this.prefs}) : super(const ThemeState()) {
    on<LoadTheme>(_onLoadTheme);
    on<ToggleTheme>(_onToggleTheme);
    on<SetThemeMode>(_onSetThemeMode);
    on<ChangeLocale>(_onChangeLocale);
  }

  void _onLoadTheme(LoadTheme event, Emitter<ThemeState> emit) {
    final savedTheme = prefs.getString(AppConstants.themeKey) ?? 'dark';
    final savedLocale = prefs.getString('language_code') ?? 'en';

    emit(
      ThemeState(
        themeMode: _themeModeFromString(savedTheme),
        locale: Locale(savedLocale),
      ),
    );
  }

  void _onToggleTheme(ToggleTheme event, Emitter<ThemeState> emit) {
    final newMode = state.themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    prefs.setString(AppConstants.themeKey, _themeModeToString(newMode));
    emit(state.copyWith(themeMode: newMode));
  }

  void _onSetThemeMode(SetThemeMode event, Emitter<ThemeState> emit) {
    prefs.setString(AppConstants.themeKey, _themeModeToString(event.themeMode));
    emit(state.copyWith(themeMode: event.themeMode));
  }

  void _onChangeLocale(ChangeLocale event, Emitter<ThemeState> emit) {
    prefs.setString('language_code', event.locale.languageCode);
    emit(state.copyWith(locale: event.locale));
  }

  ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.dark:
        return 'dark';
    }
  }
}
