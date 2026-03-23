import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cricket_live_score/core/constants/app_constants.dart';
import 'package:cricket_live_score/core/services/revenue_cat_service.dart';

// ─── Events ──────────────────────────────────────────────
abstract class PremiumEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class InitializePremium extends PremiumEvent {}

class CheckPremiumStatus extends PremiumEvent {}

/// Purchase a specific package by its RC identifier (e.g. \$rc_weekly)
class PurchasePackage extends PremiumEvent {
  final String packageIdentifier;
  PurchasePackage(this.packageIdentifier);
  @override
  List<Object?> get props => [packageIdentifier];
}

class RestoreLifetime extends PremiumEvent {}

/// Activates the 1-day PiP free trial (stores today's date)
class ActivatePipTrial extends PremiumEvent {}

// ─── State ───────────────────────────────────────────────
class PremiumState extends Equatable {
  final bool isPremium;
  final bool isLoading;
  final String? error;

  /// The calendar date (yyyy-MM-dd) on which the trial was activated, or null
  final String? pipTrialDate;

  /// Available RevenueCat packages loaded from offerings
  final List<Package> packages;

  const PremiumState({
    this.isPremium = false,
    this.isLoading = false,
    this.error,
    this.pipTrialDate,
    this.packages = const [],
  });

  /// True if trial has been activated AND today is still the same calendar date
  bool get isPipTrialActive {
    if (pipTrialDate == null) return false;
    final today = _dateString(DateTime.now());
    return pipTrialDate == today;
  }

  /// True if trial was activated but has already expired (different calendar day)
  bool get isPipTrialExpired {
    if (pipTrialDate == null) return false;
    return !isPipTrialActive;
  }

  static String _dateString(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  /// Helper to find a package by its RC identifier (e.g. \$rc_weekly)
  Package? findPackage(String identifier) {
    try {
      return packages.firstWhere((p) => p.identifier == identifier);
    } catch (_) {
      return null;
    }
  }

  PremiumState copyWith({
    bool? isPremium,
    bool? isLoading,
    String? error,
    String? pipTrialDate,
    List<Package>? packages,
    bool clearError = false,
    bool clearTrial = false,
  }) {
    return PremiumState(
      isPremium: isPremium ?? this.isPremium,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      pipTrialDate: clearTrial ? null : pipTrialDate ?? this.pipTrialDate,
      packages: packages ?? this.packages,
    );
  }

  @override
  List<Object?> get props => [
    isPremium,
    isLoading,
    error,
    pipTrialDate,
    packages,
  ];
}

// ─── BLoC ────────────────────────────────────────────────
class PremiumBloc extends Bloc<PremiumEvent, PremiumState> {
  final RevenueCatService revenueCatService;

  PremiumBloc({required this.revenueCatService}) : super(const PremiumState()) {
    on<InitializePremium>(_onInitialize);
    on<CheckPremiumStatus>(_onCheckStatus);
    on<PurchasePackage>(_onPurchase);
    on<RestoreLifetime>(_onRestore);
    on<ActivatePipTrial>(_onActivateTrial);
  }

  Future<void> _onInitialize(
    InitializePremium event,
    Emitter<PremiumState> emit,
  ) async {
    debugPrint('[PremiumBloc] _onInitialize START');

    // If packages are already cached from main(), skip the loading spinner
    final alreadyCached = revenueCatService.cachedPackages.isNotEmpty;
    if (!alreadyCached) {
      emit(state.copyWith(isLoading: true));
    }

    await revenueCatService.init();
    debugPrint('[PremiumBloc] RevenueCat init done');
    final prefs = await SharedPreferences.getInstance();
    final trialDate = prefs.getString(AppConstants.pipTrialDateKey);

    // DEV OVERRIDE: force premium on without a real purchase
    final rcPremium = await revenueCatService.isUserPremium();
    debugPrint(
      '[PremiumBloc] devPremiumOverride=${AppConstants.devPremiumOverride}, rcPremium=$rcPremium',
    );
    final isPremium = AppConstants.devPremiumOverride || rcPremium;

    // Use cached packages (pre-fetched in main), fallback to network fetch
    final packages = await revenueCatService.getAvailablePackages();
    debugPrint('[PremiumBloc] packages loaded: ${packages.length}');
    for (final p in packages) {
      debugPrint(
        '  ↳ ${p.identifier} → ${p.storeProduct.identifier} ${p.storeProduct.priceString}',
      );
    }

    debugPrint(
      '[PremiumBloc] _onInitialize DONE → isPremium=$isPremium, trialDate=$trialDate',
    );
    emit(
      state.copyWith(
        isPremium: isPremium,
        isLoading: false,
        pipTrialDate: trialDate,
        packages: packages,
      ),
    );
  }

  Future<void> _onCheckStatus(
    CheckPremiumStatus event,
    Emitter<PremiumState> emit,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final trialDate = prefs.getString(AppConstants.pipTrialDateKey);

    // DEV OVERRIDE: force premium on without a real purchase
    final isPremium =
        AppConstants.devPremiumOverride ||
        await revenueCatService.isUserPremium();

    if (isPremium != state.isPremium || trialDate != state.pipTrialDate) {
      emit(state.copyWith(isPremium: isPremium, pipTrialDate: trialDate));
    }
  }

  Future<void> _onPurchase(
    PurchasePackage event,
    Emitter<PremiumState> emit,
  ) async {
    debugPrint('[PremiumBloc] _onPurchase START → ${event.packageIdentifier}');
    // Clear any previous error so the listener fires again
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      // Use packages already in state, or fetch fresh if empty
      var packages = state.packages;
      if (packages.isEmpty) {
        packages = await revenueCatService.getAvailablePackages();
      }
      debugPrint('[PremiumBloc] packages count=${packages.length}');

      // Find the requested package
      Package? target;
      try {
        target = packages.firstWhere(
          (p) => p.identifier == event.packageIdentifier,
        );
      } catch (_) {
        target = null;
      }

      if (target != null) {
        debugPrint(
          '[PremiumBloc] purchasing package: ${target.identifier} → ${target.storeProduct.identifier}',
        );
        final result = await revenueCatService.purchasePackage(target);
        debugPrint('[PremiumBloc] purchase success=${result.success}');
        if (result.success) {
          emit(state.copyWith(isPremium: true, isLoading: false));
        } else {
          emit(
            state.copyWith(
              isLoading: false,
              error: result.errorMessage ?? 'Purchase failed',
            ),
          );
        }
      } else {
        // Build a meaningful error from the diagnostic logs
        final lastError = revenueCatService.diagnosticLogs
            .where((l) => l.contains('❌') || l.contains('⚠️'))
            .lastOrNull;
        final errorMsg =
            lastError ??
            'Package "${event.packageIdentifier}" not found — check RevenueCat dashboard';
        debugPrint('[PremiumBloc] $errorMsg');
        emit(state.copyWith(isLoading: false, error: errorMsg));
      }
    } catch (e) {
      debugPrint('[PremiumBloc] purchase error: $e');
      revenueCatService.diagnosticLogs.add('❌ Bloc catch: $e');
      emit(
        state.copyWith(
          isLoading: false,
          error: 'Something went wrong. Please try again later.',
        ),
      );
    }
  }

  Future<void> _onRestore(
    RestoreLifetime event,
    Emitter<PremiumState> emit,
  ) async {
    debugPrint('[PremiumBloc] _onRestore START');
    emit(state.copyWith(isLoading: true, clearError: true));
    final success = await revenueCatService.restorePurchases();
    debugPrint('[PremiumBloc] restore success=$success');
    emit(state.copyWith(isPremium: success, isLoading: false));
  }

  Future<void> _onActivateTrial(
    ActivatePipTrial event,
    Emitter<PremiumState> emit,
  ) async {
    final today =
        '${DateTime.now().year}-'
        '${DateTime.now().month.toString().padLeft(2, '0')}-'
        '${DateTime.now().day.toString().padLeft(2, '0')}';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.pipTrialDateKey, today);
    emit(state.copyWith(pipTrialDate: today));
  }
}
