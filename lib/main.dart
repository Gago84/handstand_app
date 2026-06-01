import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

import 'firebase_options.dart'; // 👈 QUAN TRỌNG
import 'Services/premium_access_service.dart';
import 'screens/home_screen.dart';
import 'screens/premium_screen.dart';
import 'screens/prerequisite_screen.dart';
import 'screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // 👈 QUAN TRỌNG
  );

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final prefs = await SharedPreferences.getInstance();
  final skipWelcome = prefs.getBool('skip_welcome_screen') ?? false;
  final passedRequirements =
      prefs.getBool('initial_requirements_passed') ?? false;
  final premiumActive = await PremiumAccessService.hasActiveCachedPremium();

  runApp(
    HandstandApp(
      skipWelcome: skipWelcome,
      passedRequirements: passedRequirements,
      premiumActive: premiumActive,
    ),
  );
}

class HandstandApp extends StatelessWidget {
  const HandstandApp({
    super.key,
    this.skipWelcome = false,
    this.passedRequirements = false,
    this.premiumActive = false,
    this.enableUpgradeCheck = true,
  });

  final bool skipWelcome;
  final bool passedRequirements;
  final bool premiumActive;
  final bool enableUpgradeCheck;

  @override
  Widget build(BuildContext context) {
    final Widget startScreen;
    if (!skipWelcome) {
      startScreen = const WelcomeScreen();
    } else if (!passedRequirements) {
      startScreen = const PrerequisiteScreen();
    } else if (!premiumActive && !kDebugMode) {
      startScreen = const PremiumScreen(requirePurchase: true);
    } else {
      startScreen = const HomeScreen();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Handstand Free',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: enableUpgradeCheck
          ? UpgradeAlert(showIgnore: false, showLater: true, child: startScreen)
          : startScreen,
    );
  }
}
