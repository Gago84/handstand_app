import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart'; // 👈 QUAN TRỌNG
import 'screens/home_screen.dart';
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

  runApp(
    HandstandApp(
      skipWelcome: skipWelcome,
      passedRequirements: passedRequirements,
    ),
  );
}

class HandstandApp extends StatelessWidget {
  const HandstandApp({
    super.key,
    this.skipWelcome = false,
    this.passedRequirements = false,
  });

  final bool skipWelcome;
  final bool passedRequirements;

  @override
  Widget build(BuildContext context) {
    final Widget startScreen = skipWelcome
        ? (passedRequirements ? const HomeScreen() : const PrerequisiteScreen())
        : const WelcomeScreen();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Handstand Free',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: startScreen,
    );
  }
}
