import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cricket_live_score/core/network/network_info.dart';
import 'package:cricket_live_score/core/theme/theme_bloc.dart';
import 'package:cricket_live_score/features/auth/data/datasources/auth_datasource.dart';
import 'package:cricket_live_score/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:cricket_live_score/features/auth/domain/repositories/auth_repository.dart';
import 'package:cricket_live_score/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cricket_live_score/features/home/presentation/bloc/home_bloc.dart';
import 'package:cricket_live_score/features/matches/data/datasources/cricket_datasource.dart';
import 'package:cricket_live_score/features/matches/data/datasources/api_cricket_datasource.dart';
import 'package:cricket_live_score/features/matches/data/repositories/cricket_repository.dart';
import 'package:cricket_live_score/features/matches/presentation/bloc/match_detail_bloc.dart';
import 'package:cricket_live_score/features/players/presentation/bloc/players_bloc.dart';
import 'package:cricket_live_score/features/series/presentation/bloc/series_bloc.dart';
import 'package:cricket_live_score/features/wallet/presentation/bloc/leaderboard_cubit.dart';
import 'package:cricket_live_score/features/wallet/presentation/bloc/wallet_cubit.dart';
import 'package:cricket_live_score/core/services/revenue_cat_service.dart';
import 'package:cricket_live_score/features/profile/presentation/bloc/premium_bloc.dart';
import 'package:cricket_live_score/features/ugc/data/repositories/ugc_repository.dart';
import 'package:cricket_live_score/features/ugc/presentation/cubit/ugc_cubit.dart';
import 'package:cricket_live_score/core/services/install_counter_service.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // ─── External ──────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => prefs);
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingleton(() => GoogleSignIn());
  sl.registerLazySingleton(() => Connectivity());
  sl.registerLazySingleton(() => http.Client());

  // ─── Core ──────────────────────────────────────────────
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  // ─── Theme ─────────────────────────────────────────────
  sl.registerFactory(() => ThemeBloc(prefs: sl()));

  // ─── RevenueCat ────────────────────────────────────────
  sl.registerLazySingleton(() => RevenueCatService());
  sl.registerFactory(() => PremiumBloc(revenueCatService: sl()));

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
  sl.registerFactory(() => WalletCubit(prefs: sl()));
  sl.registerFactory(() => LeaderboardCubit(prefs: sl()));

  // ─── UGC ────────────────────────────────────────────────
  sl.registerLazySingleton(() => UGCRepository(sl<FirebaseFirestore>(), sl<FirebaseStorage>()));
  sl.registerFactory(() => UGCCubit(sl()));
  // ─── Install Counter ──────────────────────────────────
  sl.registerLazySingleton(() => InstallCounterService(sl(), sl()));
}
