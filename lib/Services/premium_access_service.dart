import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PremiumAccessService {
  static const _legacyPremiumKey = 'premium_active';
  static const _legacyMigrationUsedKey = 'premium_legacy_migration_used';
  static const _expiryKey = 'premium_expiry_milliseconds';
  static const _productKey = 'premium_product_id';
  static const _pendingAndroidDurationDaysKey =
      'premium_pending_android_duration_days';
  static const _legacyMigrationGrace = Duration(days: 7);

  static const _subscriptionDurations = <String, Duration>{
    'premium_monthly': Duration(days: 31),
    'premium_quarterly': Duration(days: 93),
    'premium_semiannual': Duration(days: 186),
    'premium_yearly': Duration(days: 366),
    // Google Play purchase callbacks only return the product id, not the base
    // plan. Use a conservative fallback for restores on a new device.
    'premium': Duration(days: 31),
  };

  static const _androidBasePlanDurations = <String, Duration>{
    'monthly': Duration(days: 31),
    'quarterly': Duration(days: 93),
    'semiannual': Duration(days: 186),
    'yearly': Duration(days: 366),
  };

  static Future<bool> hasActiveCachedPremium({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final expiryMilliseconds = prefs.getInt(_expiryKey);
    final currentTime = now ?? DateTime.now();

    if (expiryMilliseconds == null) {
      final hadLegacyPremium = prefs.getBool(_legacyPremiumKey) ?? false;
      final migrationUsed = prefs.getBool(_legacyMigrationUsedKey) ?? false;
      if (hadLegacyPremium && !migrationUsed) {
        final expiry = currentTime.add(_legacyMigrationGrace);
        await prefs.setInt(_expiryKey, expiry.millisecondsSinceEpoch);
        await prefs.setString(_productKey, 'legacy_migration');
        await prefs.setBool(_legacyMigrationUsedKey, true);
        await prefs.remove(_legacyPremiumKey);
        return true;
      }

      await prefs.remove(_legacyPremiumKey);
      return false;
    }

    final expiry = DateTime.fromMillisecondsSinceEpoch(expiryMilliseconds);
    if (!expiry.isAfter(currentTime)) {
      await clearCachedPremium();
      return false;
    }

    return true;
  }

  static Future<bool> recordStorePurchase(
    PurchaseDetails purchase, {
    DateTime? now,
  }) async {
    final duration = await _durationForPurchase(purchase.productID);
    final verificationData = purchase.verificationData.serverVerificationData;
    final purchaseDate = _purchaseDate(purchase.transactionDate);

    if (purchase.status != PurchaseStatus.purchased &&
        purchase.status != PurchaseStatus.restored) {
      return false;
    }

    if (duration == null ||
        verificationData.isEmpty ||
        purchaseDate == null ||
        purchaseDate.isAfter(
          (now ?? DateTime.now()).add(const Duration(days: 1)),
        )) {
      return false;
    }

    final expiry = purchaseDate.add(duration);
    if (!expiry.isAfter(now ?? DateTime.now())) {
      await clearCachedPremium();
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_expiryKey, expiry.millisecondsSinceEpoch);
    await prefs.setString(_productKey, purchase.productID);
    await prefs.remove(_legacyPremiumKey);
    await prefs.setBool(_legacyMigrationUsedKey, true);
    await prefs.remove(_pendingAndroidDurationDaysKey);
    return true;
  }

  static Future<void> rememberPendingAndroidBasePlan(String basePlanId) async {
    final duration = _androidBasePlanDurations[basePlanId];
    if (duration == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_pendingAndroidDurationDaysKey, duration.inDays);
  }

  static Future<void> clearCachedPremium() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyPremiumKey);
    await prefs.remove(_expiryKey);
    await prefs.remove(_productKey);
    await prefs.remove(_pendingAndroidDurationDaysKey);
  }

  static Future<Duration?> _durationForPurchase(String productId) async {
    if (productId != 'premium') return _subscriptionDurations[productId];

    final prefs = await SharedPreferences.getInstance();
    final pendingDays = prefs.getInt(_pendingAndroidDurationDaysKey);
    return pendingDays == null
        ? _subscriptionDurations[productId]
        : Duration(days: pendingDays);
  }

  static DateTime? _purchaseDate(String? transactionDate) {
    final milliseconds = int.tryParse(transactionDate ?? '');
    if (milliseconds == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(milliseconds);
  }
}
