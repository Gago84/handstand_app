import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
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