import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({Key? key}) : super(key: key);

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  final InAppPurchase _iap = InAppPurchase.instance;

  final Set<String> _kIds = {
    'com.giang.handstand.premium.monthly',
    'com.giang.handstand.premium.3month',
  };

  List<ProductDetails> _products = [];
  bool _isLoading = true;
  bool isSubscribed = false;

  void disableAds() {
    print("🚫 Ads disabled");
  }

  @override
  void initState() {
    super.initState();
    loadSubscription();
    initStore();
    listenPurchase();
    _iap.restorePurchases();
  }

  Future<void> initStore() async {
    final bool available = await _iap.isAvailable();

    if (!available) {
      print("❌ Store not available");
      setState(() => _isLoading = false);
      return;
    }

    await loadProducts();
  }

  Future<void> loadProducts() async {
    final response = await _iap.queryProductDetails(_kIds);

    if (response.notFoundIDs.isNotEmpty) {
      print("❌ Not found: ${response.notFoundIDs}");
    }

    setState(() {
      _products = response.productDetails;
      _isLoading = false;
    });

    print("✅ Loaded products: ${_products.map((e) => e.id)}");
  }

  Future<void> loadSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool('isSubscribed') ?? false;

    print("🔥 isSubscribed from prefs: $value");

    setState(() {
      isSubscribed = value;
    });

    if (value) {
      disableAds();
    }
  }

  Future<void> saveSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSubscribed', true);
  }

  void buy(ProductDetails product) {
    final purchaseParam = PurchaseParam(productDetails: product);
    _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void listenPurchase() {
    _iap.purchaseStream.listen((purchases) {
      for (var purchase in purchases) {
        if (purchase.status == PurchaseStatus.pending) {
          print("⏳ Purchase pending...");
        }

        if (purchase.status == PurchaseStatus.error) {
          print("❌ Error: ${purchase.error}");
        }

        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          print("✅ Purchase success");

          setState(() {
            isSubscribed = true;
          });

          saveSubscription();
          disableAds();

          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
        }
      }
    });
  }

  Widget buildProduct(ProductDetails product) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: ListTile(
        title: Text(product.title),
        subtitle: Text(product.description),
        trailing: Text(product.price),
        onTap: () => buy(product),
      ),
    );
  }

  Widget restoreButton() {
    return TextButton(
      onPressed: () {
        _iap.restorePurchases();
      },
      child: const Text("Restore Purchase"),
    );
  }

  Widget infoText() {
    return const Column(
      children: [
        Text("Auto-renewable subscription"),
        Text("Subscription will auto-renew unless canceled"),
        Text("Cancel anytime in Settings"),
        SizedBox(height: 10),
        Text("Terms of Use"),
        Text("Privacy Policy"),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Go Premium"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(child: Text("No products available"))
              : Column(
                  children: [
                    if (isSubscribed)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          "🎉 You are Premium (No Ads)",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),

                    Expanded(
                      child: ListView(
                        children:
                            _products.map((p) => buildProduct(p)).toList(),
                      ),
                    ),

                    restoreButton(),
                    const SizedBox(height: 10),
                    infoText(),
                    const SizedBox(height: 20),
                  ],
                ),
    );
  }
}