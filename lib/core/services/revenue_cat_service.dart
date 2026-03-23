import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Simple result wrapper for purchase operations.
class PurchaseResult {
  final bool success;
  final String? errorMessage;
  const PurchaseResult({required this.success, this.errorMessage});
}

class RevenueCatService {
  static const String entitlementId = 'ad_free';

  /// Diagnostic log lines collected during the last init / purchase cycle.
  /// The Premium page reads these to show a visible debug panel.
  final List<String> diagnosticLogs = [];

  void _log(String msg) {
    debugPrint('[RevenueCat] $msg');
    diagnosticLogs.add(msg);
  }

  bool _isConfigured = false;

  /// Cached packages from the last successful offerings fetch.
  List<Package> _cachedPackages = [];

  /// Returns the cached packages without hitting the network.
  List<Package> get cachedPackages => _cachedPackages;

  Future<void> init() async {
    diagnosticLogs.clear();

    if (_isConfigured) {
      _log('✅ SDK already configured — skipping');
      return;
    }

    try {
      final rcKey = dotenv.env['REVENUE_CAT_SDK_ANDROID_KEY'] ?? '';
      if (rcKey.isEmpty) {
        _log('⚠️ REVENUE_CAT_SDK_ANDROID_KEY is empty!');
        return;
      }

      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);
      await Purchases.configure(PurchasesConfiguration(rcKey));
      _isConfigured = true;
      _log('✅ Purchases.configure() done');

      // Force fresh fetch (clear stale cache)
      await Purchases.invalidateCustomerInfoCache();
      _log('✅ Customer info cache invalidated');
    } catch (e) {
      _log('❌ RevenueCat init failed: $e');
    }
  }

  Future<bool> isUserPremium() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      final allEntitlements = customerInfo.entitlements.all;
      _log('Entitlements count: ${allEntitlements.length}');
      for (final entry in allEntitlements.entries) {
        _log('  ↳ ${entry.key}: isActive=${entry.value.isActive}');
      }
      final isActive = allEntitlements[entitlementId]?.isActive ?? false;
      _log('entitlement "$entitlementId" active=$isActive');
      return isActive;
    } catch (e) {
      _log('❌ Error fetching customer info: $e');
      return false;
    }
  }

  Future<List<Package>> getAvailablePackages({
    bool forceRefresh = false,
  }) async {
    // Return cached packages unless caller explicitly wants a refresh
    if (!forceRefresh && _cachedPackages.isNotEmpty) {
      _log('Returning ${_cachedPackages.length} cached packages');
      return _cachedPackages;
    }
    try {
      Offerings offerings = await Purchases.getOfferings();
      _log(
        'Offerings fetched. current=${offerings.current?.identifier ?? "NULL"}',
      );
      if (offerings.current != null) {
        final pkgs = offerings.current!.availablePackages;
        _log('Available packages: ${pkgs.length}');
        for (final p in pkgs) {
          _log(
            '  ↳ ${p.identifier} — ${p.storeProduct.identifier} ${p.storeProduct.priceString}',
          );
        }
        _cachedPackages = pkgs;
        return pkgs;
      } else {
        _log('⚠️ offerings.current is NULL — no current offering configured');
        // List all offerings for debug
        final allOfferings = offerings.all;
        _log('All offerings keys: ${allOfferings.keys.toList()}');
      }
    } catch (e) {
      _log('❌ Error fetching offerings: $e');
    }
    return [];
  }

  Future<PurchaseResult> purchasePackage(Package package) async {
    _log('Purchasing package: ${package.identifier}');
    _log('  storeProduct: ${package.storeProduct.identifier}');
    _log('  price: ${package.storeProduct.priceString}');
    try {
      CustomerInfo customerInfo = (await Purchases.purchasePackage(
        package,
      )).customerInfo;
      final isActive =
          customerInfo.entitlements.all[entitlementId]?.isActive ?? false;
      _log('Purchase done → "$entitlementId" active=$isActive');
      return PurchaseResult(success: isActive);
    } catch (e) {
      _log('❌ Purchase error (raw): $e');
      _log('❌ Error type: ${e.runtimeType}');
      final friendlyMessage = _friendlyErrorMessage(e);
      return PurchaseResult(success: false, errorMessage: friendlyMessage);
    }
  }

  /// Maps raw purchase exceptions to user-readable messages.
  String _friendlyErrorMessage(Object e) {
    final raw = e.toString();

    // User cancelled the purchase flow
    if (raw.contains('PurchaseCancelledError') ||
        raw.contains('userCancelled')) {
      return 'cancelled'; // sentinel — UI can silently ignore
    }

    // Debug / unsigned APK
    if (raw.contains('DEVELOPER_ERROR') ||
        raw.contains('not configured for billing')) {
      return kDebugMode
          ? 'Purchases require a signed release build. Use an internal testing APK.'
          : 'Unable to connect to Google Play. Please try again later.';
    }

    // Network / store issues
    if (raw.contains('StoreProblemError') ||
        raw.contains('NETWORK_ERROR') ||
        raw.contains('SERVICE_UNAVAILABLE')) {
      return 'Could not reach Google Play. Check your internet and try again.';
    }

    // Product not available
    if (raw.contains('ProductNotAvailableForPurchaseError') ||
        raw.contains('ITEM_UNAVAILABLE') ||
        raw.contains('ITEM_NOT_OWNED') ||
        raw.contains('itemAlreadyOwned') ||
        raw.contains('not available for purchase') ||
        raw.contains('item you requested')) {
      return 'This plan is currently unavailable. Please try again later.';
    }

    // Already owned
    if (raw.contains('ITEM_ALREADY_OWNED') ||
        raw.contains('ProductAlreadyPurchasedError')) {
      return 'You already own this plan. Try restoring your purchases.';
    }

    // Payment pending
    if (raw.contains('PaymentPendingError')) {
      return 'Your payment is being processed. It may take a moment.';
    }

    // Generic fallback
    return 'Something went wrong. Please try again later.';
  }

  Future<bool> restorePurchases() async {
    _log('Restoring purchases...');
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      final allEntitlements = customerInfo.entitlements.all;
      _log('Restore done. Entitlements: ${allEntitlements.length}');
      for (final entry in allEntitlements.entries) {
        _log('  ↳ ${entry.key}: isActive=${entry.value.isActive}');
      }
      final isActive = allEntitlements[entitlementId]?.isActive ?? false;
      _log('entitlement "$entitlementId" active=$isActive');
      return isActive;
    } catch (e) {
      _log('❌ Error restoring purchases: $e');
      return false;
    }
  }
}
