import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';

class StepFinalScreen extends StatefulWidget {
  const StepFinalScreen({super.key});

  @override
  State<StepFinalScreen> createState() => _StepFinalScreenState();
}

class _StepFinalScreenState extends State<StepFinalScreen> {
  int total = 0;
  int good = 0;
  int practice = 0;

  @override
  void initState() {
    super.initState();
    loadData();
  }

void loadData() async {
  final prefs = await SharedPreferences.getInstance();

  int totalCount = 0;
  int goodCount = 0;
  int practiceCount = 0;

  // 🔥 loop tất cả step (0 → 5)
  for (int i = 0; i < 6; i++) {
    final good = prefs.getInt("step_${i}_good") ?? 0;
    final bad = prefs.getInt("step_${i}_bad") ?? 0;

    goodCount += good;
    practiceCount += bad;
    totalCount += good + bad;
  }

  setState(() {
    total = totalCount;
    good = goodCount;
    practice = practiceCount;
  });
}

  @override
  Widget build(BuildContext context) {
    final passed = good >= 3;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(), // ✅ iOS scroll feel
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40), // ✅ fix bottom cut
            child: Column(
              children: [
                const SizedBox(height: 30),

                // 🎉 TITLE
                const Text(
                  "🎉 You Did It",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  passed
                      ? "You reached a stable handstand"
                      : "You're very close to a stable handstand",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 30),

                // 📊 STATS CARD
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      color: Colors.grey.withOpacity(0.1),
                      child: Column(
                        children: [
                          _stat("Total sessions", total),
                          _stat("👍 Good reps", good),
                          _stat("😓 Practice reps", practice),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // 💪 MESSAGE
                Text(
                  "Handstand takes consistent daily practice — just 10–15 minutes a day.\n\nTrue progress comes when both your body and mind are in balance. Without good physical and mental health, reaching a freestanding handstand is very difficult.\n\nStay consistent, and make this practice part of your long-term routine to build strength, control, and overall well-being.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 30), // ✅ replace Spacer()

                // 🔒 PREMIUM CARD
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        "🚀 Next Level",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        "Unlock advanced handstand balance,\nfreestanding control and transitions.",
                        style: TextStyle(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      GestureDetector(
                        onTap: () {
                          // 👉 TODO: open paywall
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Text(
                            "Unlock Premium 🔥",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String title, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            "$value",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}