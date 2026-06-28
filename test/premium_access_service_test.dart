import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:handstand_app/Services/premium_access_service.dart';

void main() {
  final now = DateTime(2026, 6, 1, 12);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('legacy premium flag gets one short migration grace period', () async {
    SharedPreferences.setMockInitialValues({'premium_active': true});

    expect(await PremiumAccessService.hasActiveCachedPremium(now: now), isTrue);
    expect(
      await PremiumAccessService.hasActiveCachedPremium(
        now: now.add(const Duration(days: 6)),
      ),
      isTrue,
    );
    expect(
      await PremiumAccessService.hasActiveCachedPremium(
        now: now.add(const Duration(days: 8)),
      ),
      isFalse,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey('premium_active'), isFalse);
    expect(prefs.getBool('premium_legacy_migration_used'), isTrue);
  });

  test('legacy migration is not repeated', () async {
    SharedPreferences.setMockInitialValues({
      'premium_active': true,
      'premium_legacy_migration_used': true,
    });

    expect(
      await PremiumAccessService.hasActiveCachedPremium(now: now),
      isFalse,
    );
  });

  test('accepted store purchase creates an expiring entitlement', () async {
    final accepted = await PremiumAccessService.recordStorePurchase(
      _purchase(
        productID: 'premium_monthly',
        transactionDate: now.millisecondsSinceEpoch.toString(),
      ),
      now: now,
    );

    expect(accepted, isTrue);
    expect(
      await PremiumAccessService.hasActiveCachedPremium(
        now: now.add(const Duration(days: 30)),
      ),
      isTrue,
    );
    expect(
      await PremiumAccessService.hasActiveCachedPremium(
        now: now.add(const Duration(days: 32)),
      ),
      isFalse,
    );
  });

  test('unknown products and empty verification data are rejected', () async {
    expect(
      await PremiumAccessService.recordStorePurchase(
        _purchase(
          productID: 'unexpected_product',
          transactionDate: now.millisecondsSinceEpoch.toString(),
        ),
        now: now,
      ),
      isFalse,
    );
    expect(
      await PremiumAccessService.recordStorePurchase(
        _purchase(
          productID: 'premium_yearly',
          transactionDate: now.millisecondsSinceEpoch.toString(),
          verificationData: '',
        ),
        now: now,
      ),
      isFalse,
    );
  });

  test('google play purchase uses the selected base plan duration', () async {
    await PremiumAccessService.rememberPendingAndroidBasePlan('quarterly');

    final accepted = await PremiumAccessService.recordStorePurchase(
      _purchase(
        productID: 'premium',
        transactionDate: now.millisecondsSinceEpoch.toString(),
      ),
      now: now,
    );

    expect(accepted, isTrue);
    expect(
      await PremiumAccessService.hasActiveCachedPremium(
        now: now.add(const Duration(days: 92)),
      ),
      isTrue,
    );
    expect(
      await PremiumAccessService.hasActiveCachedPremium(
        now: now.add(const Duration(days: 94)),
      ),
      isFalse,
    );
  });
}

PurchaseDetails _purchase({
  required String productID,
  required String transactionDate,
  String verificationData = 'store-verification-data',
}) {
  return PurchaseDetails(
    productID: productID,
    verificationData: PurchaseVerificationData(
      localVerificationData: verificationData,
      serverVerificationData: verificationData,
      source: 'app_store',
    ),
    transactionDate: transactionDate,
    status: PurchaseStatus.purchased,
  );
}
