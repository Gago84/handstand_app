import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // 👈 QUAN TRỌNG
import 'screens/home_screen.dart';
import 'package:flutter/services.dart';
import 'screens/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // 👈 QUAN TRỌNG
  );


  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const HandstandApp());
}

class HandstandApp extends StatelessWidget {
  const HandstandApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Handstand Free',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: const WelcomeScreen(),
    );
  }
}