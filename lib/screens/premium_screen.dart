import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'home_screen.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key, this.requirePurchase = false});

  final bool requirePurchase;

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  static const Set<String> _androidProductIds = {'premium'};
  static const Set<String> _appleProductIds = {
    'premium_monthly',
    'premium_quarterly',
    'premium_semiannual',
    'premium_yearly',
  };
  static final Uri _termsOfUseUri = Uri.parse(
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
  );

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late final StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;

  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _isLoading = true;
  bool _isPremium = false;
  String? _message;

  Set<String> get _productIds {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return _appleProductIds;
    }
    return _androidProductIds;
  }

  @override
  void initState() {
    super.initState();
    _purchaseSubscription = _inAppPurchase.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (error) {
        _setMessage('Purchase update failed: $error');
      },
    );
    _loadPremiumState();
    _loadProducts();
  }

  @override
  void dispose() {
    _purchaseSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadPremiumState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _isPremium = prefs.getBool('premium_active') ?? false;
    });
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    final available = await _inAppPurchase.isAvailable();
    if (!available) {
      if (!mounted) return;
      setState(() {
        _isAvailable = false;
        _isLoading = false;
        _message = 'In-app purchases are not available on this device.';
      });
      return;
    }

    final response = await _inAppPurchase.queryProductDetails(_productIds);
    if (!mounted) return;

    final products = [...response.productDetails]..sort(_sortProducts);
    setState(() {
      _isAvailable = true;
      _products = products;
      _isLoading = false;
      _message =
          response.error?.message ??
          (products.isEmpty
              ? 'No subscription plans found. Install the app from the store test track and use a sandbox or tester account.'
              : null);
    });
  }

  int _sortProducts(ProductDetails a, ProductDetails b) {
    const order = {'monthly': 0, 'quarterly': 1, 'semiannual': 2, 'yearly': 3};
    return (_planOrder(a, order)).compareTo(_planOrder(b, order));
  }

  int _planOrder(ProductDetails product, Map<String, int> order) {
    final id = _basePlanId(product);
    return order[id] ?? 99;
  }

  String _basePlanId(ProductDetails product) {
    if (product is GooglePlayProductDetails &&
        product.subscriptionIndex != null) {
      return product
          .productDetails
          .subscriptionOfferDetails![product.subscriptionIndex!]
          .basePlanId;
    }
    return switch (product.id) {
      'premium_monthly' => 'monthly',
      'premium_quarterly' => 'quarterly',
      'premium_semiannual' => 'semiannual',
      'premium_yearly' => 'yearly',
      _ => product.id,
    };
  }

  String _planTitle(ProductDetails product) {
    return switch (_basePlanId(product)) {
      'monthly' => 'Experience',
      'quarterly' => 'Build a habit',
      'semiannual' => 'Consistent practice',
      'yearly' => 'Best value',
      _ => product.title,
    };
  }

  String _planDuration(ProductDetails product) {
    return switch (_basePlanId(product)) {
      'monthly' => '1 month',
      'quarterly' => '3 months',
      'semiannual' => '6 months',
      'yearly' => '12 months',
      _ => 'Subscription',
    };
  }

  Future<void> _buy(ProductDetails product) async {
    setState(() {
      _message = null;
    });

    final PurchaseParam purchaseParam;
    if (defaultTargetPlatform == TargetPlatform.android &&
        product is GooglePlayProductDetails) {
      purchaseParam = GooglePlayPurchaseParam(
        productDetails: product,
        offerToken: product.offerToken,
      );
    } else {
      purchaseParam = PurchaseParam(productDetails: product);
    }

    await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _message = null;
    });
    await _inAppPurchase.restorePurchases();
  }

  Future<void> _openUrl(Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      _setMessage('Could not open ${uri.toString()}');
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        _setMessage('Purchase is pending.');
      } else if (purchase.status == PurchaseStatus.error) {
        _setMessage(purchase.error?.message ?? 'Purchase failed.');
      } else if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        await _unlockPremium();
        _setMessage('Premium is active.');
        if (widget.requirePurchase) {
          _goToHome();
        }
      } else if (purchase.status == PurchaseStatus.canceled) {
        _setMessage('Purchase canceled.');
      }

      if (purchase.pendingCompletePurchase) {
        await _inAppPurchase.completePurchase(purchase);
      }
    }
  }

  Future<void> _unlockPremium() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('premium_active', true);
    if (!mounted) return;
    setState(() {
      _isPremium = true;
    });
  }

  void _setMessage(String message) {
    if (!mounted) return;
    setState(() {
      _message = message;
    });
  }

  void _goToHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101214),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101214),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Premium'),
        actions: [
          IconButton(
            tooltip: 'Restore purchases',
            onPressed: _isAvailable ? _restorePurchases : null,
            icon: const Icon(Icons.restore),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProducts,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _Header(isPremium: _isPremium),
              const SizedBox(height: 16),
              if (_message != null) ...[
                _StatusMessage(message: _message!),
                const SizedBox(height: 16),
              ],
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_products.isEmpty)
                _EmptyPlans(onRetry: _loadProducts)
              else
                for (final product in _products)
                  _PlanTile(
                    title: _planTitle(product),
                    duration: _planDuration(product),
                    price: product.price,
                    onPressed: () => _buy(product),
                  ),
              if (widget.requirePurchase && _isPremium) ...[
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white38),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _goToHome,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text(
                      'Continue to training',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Payment is charged through your store account. Subscription renews automatically unless canceled before renewal.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              _LegalLinks(onOpenTerms: () => _openUrl(_termsOfUseUri)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalLinks extends StatelessWidget {
  const _LegalLinks({required this.onOpenTerms});

  final VoidCallback onOpenTerms;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Colors.orange.shade200,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        onPressed: onOpenTerms,
        child: const Text('Terms of Use (EULA)'),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.isPremium});

  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1F22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium, color: Colors.orange),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isPremium ? 'Premium active' : 'Handstand Trainer Premium',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Unlock premium training access and keep your practice consistent.',
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.title,
    required this.duration,
    required this.price,
    required this.onPressed,
  });

  final String title;
  final String duration;
  final String price;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171A1D),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  duration,
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: onPressed,
            child: Text(
              price,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message, style: const TextStyle(color: Colors.white70)),
    );
  }
}

class _EmptyPlans extends StatelessWidget {
  const _EmptyPlans({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          const Icon(Icons.storefront, color: Colors.white54, size: 48),
          const SizedBox(height: 14),
          const Text(
            'No plans available',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Open this build from the store test track after the subscription changes are active.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
