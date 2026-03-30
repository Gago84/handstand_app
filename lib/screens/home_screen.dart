import 'package:flutter/material.dart';
import '../models/exercise.dart';
import 'exercise_detail_screen.dart';
import 'about_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/banner_ad_widget.dart';
import 'subscription_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/progress_service.dart';
import 'dart:async';
import 'StepFinalScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  Timer? _timer;
  bool isSubscribed = false;

  bool isWarmupValid = false;
  Set<String> completedSteps = {};

  @override
  void initState() {
    super.initState();

    loadSubscription();
    loadWarmupStatus();
    loadProgress();

_timer = Timer.periodic(const Duration(seconds: 1), (_) async {
  final valid = await ProgressService.isWarmupValid();

  if (valid != isWarmupValid) {
    setState(() {
      isWarmupValid = valid;
    });
  }
});
  }

  Future<void> loadSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool('isSubscribed') ?? false;

    setState(() {
      isSubscribed = value;
    });
  }

  Future<void> loadWarmupStatus() async {
    final valid = await ProgressService.isWarmupValid();

    setState(() {
      isWarmupValid = valid;
    });
  }

  Future<void> loadProgress() async {
    final list = await ProgressService.getCompleted();

    setState(() {
      completedSteps = list.toSet();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text("Handstand Training",
            style: TextStyle(      
              color: Colors.white, // 🔥 FIX HERE
              fontWeight: FontWeight.bold,
              fontSize: 20,)
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(
          color: Colors.white, // 🔥 icons also white
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SubscriptionPage()),
              );
              await loadProgress();
              loadSubscription();
            },
          )
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('HandStand')
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No exercises found"));
          }

          final exercises = snapshot.data!.docs.map((doc) {
            return Exercise.fromFirestore(
                doc.id, doc.data() as Map<String, dynamic>);
          }).toList();

          exercises.sort((a, b) => a.order.compareTo(b.order));

          final totalSteps = exercises.length;
          final doneSteps = completedSteps.length;
          final progress =
              totalSteps == 0 ? 0.0 : doneSteps / totalSteps;

          return Column(
            children: [

              // 🔥 HEADER (GRADIENT + PROGRESS)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0F2027),
                      Color(0xFF203A43),
                      Color(0xFF2C5364),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$doneSteps / $totalSteps completed",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF00E676),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 🔥 LIST
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(top: 10, bottom: 16),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    final isFinalStep = exercise.id == "FinalMessage";
                    final prevStepGood =
                        completedSteps.contains("step_${index - 1}");

                    final isLocked =
                        index > 0 && (!isWarmupValid || !prevStepGood);

                    return FutureBuilder<Map<String, int>>(
                      future: ProgressService.getFeedback(index),
                      builder: (context, snapshot) {
                        final good = snapshot.data?["good"] ?? 0;
                        final bad = snapshot.data?["bad"] ?? 0;

                        return GestureDetector(
 onTap: () async {
  // 🔒 LOCK logic
  if (isLocked) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Complete warm-up & previous step first"),
      ),
    );
    return;
  }

  // ✅ FINAL STEP
  if (isFinalStep) {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StepFinalScreen(),
      ),
    );
    return;
  }

  // 👉 NORMAL STEP
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ExerciseDetailScreen(
        exercise: exercise,
        index: index,
      ),
    ),
  );

  await loadProgress();
  await loadWarmupStatus();
  setState(() {}); // 🔥 IMPORTANT: force rebuild list + FutureBuilder
},
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1E1E),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [

                                // 🔥 STEP CIRCLE
Container(
  width: 40,
  height: 40,
  decoration: BoxDecoration(
    color: isFinalStep
        ? Colors.orange
        : (isLocked ? Colors.grey : const Color(0xFF00E676)),
    shape: BoxShape.circle,
  ),
                                  child: Center(
                                    child: Text(
                                      "${index + 1}",
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 14),

                                // 🔥 TEXT
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
Text(
  isFinalStep ? "🏁 Final Challenge" : exercise.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
if (isFinalStep)
  FutureBuilder<Map<String, int>>(
    future: ProgressService.getTotals(),
    builder: (context, snapshot) {
      final good = snapshot.data?["good"] ?? 0;
      final bad = snapshot.data?["practice"] ?? 0;
      final total = snapshot.data?["total"] ?? 0;

      return Text(
        "👍 $good   😓 $bad   🔁 $total",
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
        ),
      );
    },
  )
else
Text(
  isLocked
      ? "🔒 Locked   👍 $good   😓 $bad"
      : "👍 $good   😓 $bad",
  style: TextStyle(
    color: isLocked ? Colors.white38 : Colors.white54,
    fontSize: 12,
  ),
),
                                    ],
                                  ),
                                ),

Icon(
  isFinalStep
      ? Icons.emoji_events
      : (isLocked ? Icons.lock : Icons.play_arrow),
  color: isLocked ? Colors.white38 : Colors.white70,
  size: 18,
),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),

      bottomNavigationBar: isSubscribed
          ? null
          : const SafeArea(
              child: Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: BannerAdWidget(),
              ),
            ),
    );
  }
}