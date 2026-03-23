import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cricket_live_score/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:cricket_live_score/core/di/injection_container.dart';
import 'package:cricket_live_score/core/router/app_router.dart';
import 'package:cricket_live_score/core/theme/app_theme.dart';
import 'package:cricket_live_score/core/theme/theme_bloc.dart';
import 'package:cricket_live_score/core/widgets/update_required_screen.dart';
import 'package:upgrader/upgrader.dart';
import 'package:cricket_live_score/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:cricket_live_score/features/home/presentation/bloc/home_bloc.dart';
import 'package:cricket_live_score/features/players/presentation/bloc/players_bloc.dart';
import 'package:cricket_live_score/features/series/presentation/bloc/series_bloc.dart';
import 'package:cricket_live_score/features/wallet/presentation/bloc/wallet_cubit.dart';
import 'package:cricket_live_score/core/services/notification_service.dart';
import 'package:cricket_live_score/core/widgets/connectivity_wrapper.dart';
import 'package:cricket_live_score/core/widgets/maintenance_screen.dart';
import 'package:cricket_live_score/firebase_options.dart';
import 'package:cricket_live_score/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cricket_live_score/core/utils/ad_helper.dart';
import 'package:cricket_live_score/core/widgets/ad_free_dialog.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cricket_live_score/features/profile/presentation/bloc/premium_bloc.dart';
import 'package:cricket_live_score/core/services/revenue_cat_service.dart';
import 'package:cricket_live_score/core/services/remote_config_service.dart';
import 'package:cricket_live_score/core/services/analytics_service.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cricket_live_score/core/services/install_counter_service.dart';

void main() {
  // Run all initialization inside a single zone so the Flutter bindings
  // are initialized in the same zone that later calls runApp.
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Load environment variables
      await dotenv.load(fileName: ".env");

      // Stop Google Fonts from trying to fetch fonts from the web (avoid SocketExceptions)
      GoogleFonts.config.allowRuntimeFetching = false;

      // Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Crashlytics — catch all Flutter framework errors
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      // Check connectivity BEFORE any network calls.
      final connectivityResults = await Connectivity().checkConnectivity();
      final isOnline =
          !(connectivityResults.length == 1 &&
              connectivityResults.first == ConnectivityResult.none);

      if (isOnline) {
        await RemoteConfigService.instance.init().timeout(
          const Duration(seconds: 8),
          onTimeout: () =>
              debugPrint('⚠️ RemoteConfig timed out — using defaults'),
        );
      } else {
        await RemoteConfigService.instance.initOffline();
      }

      // Analytics — log app open
      unawaited(AnalyticsService.instance.logAppOpen());

      // Dependency injection
      await initDependencies();

      // Analytics — log app install (one-time)
      unawaited(AnalyticsService.instance.logAppInstall());

      // Ads — only supported on Android and iOS
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await AdHelper.updateTestDevices();
        await MobileAds.instance.initialize();
        if (AppConstants.devPremiumOverride) {
          AdHelper.isPremium = true;
        }
        await AdHelper.init();
      }

      // System UI overlay
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );
      // Ensures the Flutter UI fills the entire screen including system bars
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

      // Notifications
      final notificationService = NotificationService();
      await notificationService.init();
      await notificationService.scheduleDailyNotification();

      // RevenueCat — init SDK and pre-load packages so prices are ready before UI
      final revenueCatService = sl<RevenueCatService>();
      await revenueCatService.init();
      
      // Install Counter — increment global install count once per install
      unawaited(sl<InstallCounterService>().logInstallOnce());
      if (isOnline) {
        await revenueCatService.getAvailablePackages().timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            debugPrint('⚠️ RevenueCat offerings timed out');
            return [];
          },
        );
      }

      // Fetch onboarding status
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding =
          AppConstants.devSkipOnboarding ||
          (prefs.getBool(AppConstants.hasSeenOnboardingKey) ?? false);

      // Call runApp in the same zone as ensureInitialized to avoid Zone mismatch
      runApp(AppRoot(hasSeenOnboarding: hasSeenOnboarding));
    },
    (error, stack) {
      // Top-level zone error handler during initialization and runtime
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}

class AppRoot extends StatelessWidget {
  final bool hasSeenOnboarding;

  const AppRoot({super.key, required this.hasSeenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(
          create: (_) => sl<ThemeBloc>()..add(LoadTheme()),
        ),
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>()..add(CheckAuthStatus()),
        ),
        BlocProvider<HomeBloc>(create: (_) => sl<HomeBloc>()),
        BlocProvider<PlayersBloc>(create: (_) => sl<PlayersBloc>()),
        BlocProvider<SeriesBloc>(create: (_) => sl<SeriesBloc>()),
        BlocProvider<WalletCubit>(create: (_) => sl<WalletCubit>()),
        BlocProvider<PremiumBloc>(
          create: (_) => sl<PremiumBloc>()..add(InitializePremium()),
        ),
      ],
      child: AppView(hasSeenOnboarding: hasSeenOnboarding),
    );
  }
}

class AppView extends StatefulWidget {
  final bool hasSeenOnboarding;
  const AppView({super.key, required this.hasSeenOnboarding});

  @override
  State<AppView> createState() => _AppViewState();
}

class _AppViewState extends State<AppView> with WidgetsBindingObserver {
  late final GoRouter _router;
  bool _isAdShowing = false;
  Timer? _adFreeDialogTimer;

  // ── Change this to Duration(minutes: 4) when ready for production ──
  static const _adFreeDialogDelay = Duration(minutes: 3);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize router once with the AuthBloc instance
    _router = createRouter(context.read<AuthBloc>(), widget.hasSeenOnboarding);

    // Give AdHelper the root navigator so it can block back during fullscreen ads
    AdHelper.navigatorKey = rootNavigatorKey;

    // Give NotificationService the root navigator for tap-to-navigate support
    NotificationService.navigatorKey = rootNavigatorKey;

    // Show sticky spin notification if the user already has a free spin available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Sync premium flag to AdHelper so all ads are suppressed for premium users.
      // We OR with devPremiumOverride to prevent the initial Bloc state (false)
      // from overriding the startup true value set in main().
      AdHelper.isPremium = context.read<PremiumBloc>().state.isPremium ||
          AppConstants.devPremiumOverride;

      if (AppConstants.devShowWalletUI) {
        final canSpin = context.read<WalletCubit>().state.canSpinFree;
        if (canSpin) {
          NotificationService().showStickySpinNotification();
        }
      }
      _startAdFreeDialogTimer();

      // Deliver any notification-button route stored before the app launched.
      // Called here so GoRouter is mounted and auth redirect has been applied.
      NotificationService().navigateFromLaunch();
    });
  }

  void _startAdFreeDialogTimer() {
    _adFreeDialogTimer?.cancel();
    _adFreeDialogTimer = Timer(_adFreeDialogDelay, () {
      if (!mounted) return;
      // Only show if user is not premium
      final isPremium = context.read<PremiumBloc>().state.isPremium;
      if (isPremium) return;

      // Use the rootNavigatorKey context so there's always a Navigator available
      final navContext = rootNavigatorKey.currentContext;
      if (navContext == null) return;

      AdFreeDialog.show(navContext);
    });
  }

  @override
  void dispose() {
    _adFreeDialogTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _onAppPaused();
    }
  }

  void _onAppPaused() {
    if (!AppConstants.devShowWalletUI) return;

    final walletCubit = context.read<WalletCubit>();
    if (walletCubit.state.canSpinFree) {
      // Re-post sticky every time app is backgrounded while spin is available
      NotificationService().showStickySpinNotification();
    } else {
      // Spin used today — remind them tomorrow morning when it resets
      NotificationService().scheduleSpinReminder();
    }
  }

  Future<void> _onAppResumed() async {
    print('🔄 App: didChangeAppLifecycleState → resumed');

    // Small delay to ensure onNewIntent's commit() has flushed before we read.
    // On some devices resumed fires before onNewIntent completes.
    await Future.delayed(const Duration(milliseconds: 300));

    // Check for a pending notification route (backgrounded button tap).
    // Kotlin writes to SharedPreferences synchronously in onNewIntent.
    await NotificationService().navigateFromLaunch();

    // Skip if a fullscreen ad (interstitial/rewarded) is currently active
    if (AdHelper.isFullscreenAdActive) {
      print('⏭️ App: Ignoring resume — fullscreen ad is active');
      return;
    }

    // Re-post sticky spin notification if user still has a free spin.
    // Always re-post on resume so it survives OS notification dismissal.
    if (AppConstants.devShowWalletUI) {
      final canSpin = context.read<WalletCubit>().state.canSpinFree;
      if (canSpin) {
        NotificationService().showStickySpinNotification();
      }
    }

    // Show App Open Ad
    if (!_isAdShowing) {
      _isAdShowing = true;
      AdHelper.showAppOpenAd(() {
        _isAdShowing = false;
      });
    } else {
      print('⏭️ App: Ignoring resume — _isAdShowing is already true');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Keep Analytics user ID in sync with auth state
        if (state is Authenticated) {
          unawaited(AnalyticsService.instance.setUserId(state.user.uid));
        } else {
          unawaited(AnalyticsService.instance.setUserId(null));
        }
      },
      child: BlocListener<PremiumBloc, PremiumState>(
        listenWhen: (previous, current) =>
            previous.isPremium != current.isPremium,
        listener: (context, state) {
          AdHelper.isPremium = state.isPremium;
          unawaited(AnalyticsService.instance.setUserPremium(state.isPremium));
        },
        child: BlocListener<WalletCubit, WalletState>(
          listenWhen: (previous, current) =>
              AppConstants.devShowWalletUI &&
              previous.canSpinFree != current.canSpinFree,
          listener: (context, state) {
            if (state.canSpinFree) {
              // Spin just became available (midnight reset) — show sticky immediately
              NotificationService().showStickySpinNotification();
            } else {
              // User just spun — cancel the sticky notification
              NotificationService().cancelSpinNotification();
            }
          },
          child: BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, themeState) {
              return MaterialApp.router(
                title: 'Cricket Live Score',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeState.themeMode,
                locale: themeState.locale,
                routerConfig: _router,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) {
                  final isUnderMaintenance =
                      RemoteConfigService.instance.underMaintenance;

                  // Force Update Check
                  final currentBuild = int.tryParse(AppConstants.appVersion.split('+')[1]) ?? 0;
                  final minRequiredBuild = int.tryParse(AppConstants.minAppVersion.split('+')[1]) ?? 0;

                  bool isUpdateRequired = false;
                  if (AppConstants.forceUpdate) {
                    if (minRequiredBuild > currentBuild) {
                      isUpdateRequired = true;
                    }
                  }

                  if (isUpdateRequired) {
                    return const UpdateRequiredScreen();
                  }

                  return UpgradeAlert(
                    upgrader: Upgrader(
                      debugLogging: false,
                      durationUntilAlertAgain: const Duration(days: 2),
                    ),
                    showIgnore: true,
                    showLater: true,
                    child: ConnectivityWrapper(
                      child: isUnderMaintenance
                          ? const MaintenanceScreen()
                          : child!,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
