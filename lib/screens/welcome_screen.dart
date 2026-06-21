import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Services/premium_access_service.dart';
import '../config/premium_gate.dart';
import 'home_screen.dart';
import 'premium_screen.dart';
import 'prerequisite_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  bool _skipNextTime = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 🌄 Background Image
          SizedBox.expand(
            child: Image.asset(
              "assets/front-por.jpg", // 👈 bạn tự thêm ảnh
              fit: BoxFit.cover,
            ),
          ),

          /// 🌫 Blur Layer
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(color: Colors.black.withValues(alpha: 0.3)),
          ),

          /// ✨ Content
          SafeArea(
            child: FadeTransition(
              opacity: _fade,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxHeight < 760;

                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      isCompact ? 20 : 32,
                      24,
                      16,
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Column(
                              children: [
                                SizedBox(height: isCompact ? 12 : 24),
                                Icon(
                                  Icons.accessibility_new,
                                  size: isCompact ? 64 : 80,
                                  color: Colors.white,
                                ),
                                SizedBox(height: isCompact ? 18 : 24),
                                const Text(
                                  "Handstand Journey",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: isCompact ? 22 : 32),
                                Text(
                                  "Thank life for the blessing of having a normal body.\n\n"
                                  "The joy of a child standing upright for the first time on their tiny feet.\n\n"
                                  "Are you ready to rediscover that joy once again—this time on your hands?\n\n"
                                  "Wishing you success on this journey, and may you reconnect with a kind of joy you may have never fully experienced before.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: isCompact ? 15 : 16,
                                    height: isCompact ? 1.45 : 1.6,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: isCompact ? 20 : 32),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              _savePreferenceAndContinue();
                            },
                            child: const Text(
                              "Get Started",
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            setState(() {
                              _skipNextTime = !_skipNextTime;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Checkbox(
                                  value: _skipNextTime,
                                  activeColor: Colors.orange,
                                  checkColor: Colors.black,
                                  side: const BorderSide(color: Colors.white70),
                                  onChanged: (value) {
                                    setState(() {
                                      _skipNextTime = value ?? false;
                                    });
                                  },
                                ),
                                const Flexible(
                                  child: Text(
                                    "Do not show this next time",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _savePreferenceAndContinue() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('skip_welcome_screen', _skipNextTime);
    final completedOnboarding =
        prefs.getBool('initial_requirements_passed') ?? false;

    Widget nextScreen = const PrerequisiteScreen();
    if (completedOnboarding) {
      final premiumActive = await PremiumAccessService.hasActiveCachedPremium();
      nextScreen = premiumActive || PremiumGate.bypassForLocalTesting
          ? const HomeScreen()
          : const PremiumScreen(requirePurchase: true);
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }
}
