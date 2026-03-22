import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // 👈 QUAN TRỌNG
import 'screens/home_screen.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // 👈 QUAN TRỌNG
  );
    // 👇 THÊM DÒNG NÀY
  await MobileAds.instance.initialize();

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
      home: const HomeScreen(),
    );
  }
}