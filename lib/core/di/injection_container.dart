import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cricketbuzz/core/network/network_info.dart';
import 'package:cricketbuzz/core/theme/theme_bloc.dart';
import 'package:cricketbuzz/features/auth/data/datasources/auth_datasource.dart';
import 'package:cricketbuzz/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:cricketbuzz/features/auth/domain/repositories/auth_repository.dart';
import 'package:cricketbuzz/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cricketbuzz/features/home/presentation/bloc/home_bloc.dart';
import 'package:cricketbuzz/features/matches/data/datasources/cricket_datasource.dart';
import 'package:cricketbuzz/features/matches/data/datasources/api_cricket_datasource.dart';
import 'package:cricketbuzz/features/matches/data/repositories/cricket_repository.dart';
import 'package:cricketbuzz/features/matches/presentation/bloc/match_detail_bloc.dart';
import 'package:cricketbuzz/features/players/presentation/bloc/players_bloc.dart';
import 'package:cricketbuzz/features/series/presentation/bloc/series_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ─── External ──────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => prefs);
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => GoogleSignIn());
  sl.registerLazySingleton(() => Connectivity());
  sl.registerLazySingleton(() => http.Client());

  // ─── Core ──────────────────────────────────────────────
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // ─── Theme ─────────────────────────────────────────────
  sl.registerFactory(() => ThemeBloc(prefs: sl()));

  // ─── Auth ──────────────────────────────────────────────
  sl.registerLazySingleton<AuthDataSource>(
    () => AuthDataSourceImpl(
      firebaseAuth: sl(),
      googleSignIn: sl(),
      firestore: sl(),
    ),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(dataSource: sl()),
  );
  sl.registerFactory(() => AuthBloc(repository: sl()));

  // ─── Cricket Data ──────────────────────────────────────
  sl.registerLazySingleton<CricketDataSource>(
    () => ApiCricketDataSource(client: sl()),
  );
  sl.registerLazySingleton<CricketRepository>(
    () => CricketRepositoryImpl(dataSource: sl()),
  );

  // ─── BLoCs ─────────────────────────────────────────────
  sl.registerFactory(() => HomeBloc(repository: sl()));
  sl.registerFactory(() => MatchDetailBloc(repository: sl()));
  sl.registerFactory(() => PlayersBloc(repository: sl()));
  sl.registerFactory(() => SeriesBloc(repository: sl()));
}
