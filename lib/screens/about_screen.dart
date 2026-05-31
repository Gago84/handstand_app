import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static final Uri _privacyPolicyUri = Uri.parse(
    'https://banana-57559.web.app/privacy-policy.html',
  );
  static final Uri _termsOfUseUri = Uri.parse(
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
  );

  Future<void> _openUrl(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("About")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const Text(
              "Handstand Free",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text("Version 1.0.9"),

            const SizedBox(height: 20),

            const Text(
              "Handstand Free helps beginners learn handstand step by step with simple exercises.",
              style: TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 30),

            const Text(
              "Contact",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text("Email: giang131084@gmail.com"),

            const SizedBox(height: 30),

            const Text(
              "Privacy",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text(
              "Training plans and instructional videos are loaded from Firebase. "
              "Subscription purchases are processed by your app store account.",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _openUrl(_privacyPolicyUri),
              child: const Text("Privacy Policy"),
            ),
            TextButton(
              onPressed: () => _openUrl(_termsOfUseUri),
              child: const Text("Terms of Use (EULA)"),
            ),
          ],
        ),
      ),
    );
  }
}
