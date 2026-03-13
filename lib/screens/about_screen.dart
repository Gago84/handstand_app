import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [

            Text(
              "Handstand Free",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

            Text("Version 1.0"),

            SizedBox(height: 20),

            Text(
              "Handstand Free helps beginners learn handstand step by step with simple exercises.",
              style: TextStyle(fontSize: 16),
            ),

            SizedBox(height: 30),

            Text(
              "Contact",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

            Text("Email: your@email.com"),

            SizedBox(height: 30),

            Text(
              "Privacy",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10),

            Text(
              "This app does not collect personal data. Videos are loaded from YouTube.",
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}