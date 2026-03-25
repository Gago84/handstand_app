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

    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      loadWarmupStatus();
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

    print("🔥 completedSteps: $completedSteps");
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Handstand Free"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AboutScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SubscriptionPage(),
                ),
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

          // 🔥 PROGRESS CALCULATION (ĐÚNG CHỖ)
          final totalSteps = exercises.length;
          final doneSteps = completedSteps.length;
          final progress =
              totalSteps == 0 ? 0.0 : doneSteps / totalSteps;

          return Column(
            children: [

              // 🔥 PROGRESS BAR UI
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Progress: $doneSteps / $totalSteps",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor:
                          const AlwaysStoppedAnimation(Colors.green),
                    ),
                  ],
                ),
              ),

              // 🔥 LIST STEP
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];

                    final isLocked =
                        index > 0 &&
                        (
                          !isWarmupValid ||
                          !completedSteps
                              .contains("step_${index - 1}")
                        );

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),

                        title: Text(
                          "Step ${index + 1}: ${exercise.title}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),

                        subtitle: Text(
                          isLocked
                              ? "🔒 Please complete Warm Up first"
                              : (exercise.description.isEmpty
                                  ? "Tap to access exercise details"
                                  : exercise.description),
                        ),

                        trailing: Icon(
                          isLocked
                              ? Icons.lock
                              : Icons.arrow_forward_ios,
                        ),

                        onTap: () async {
                          if (isLocked) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "Please complete previous step"),
                              ),
                            );
                            return;
                          }

                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ExerciseDetailScreen(
                                exercise: exercise,
                                index: index,
                              ),
                            ),
                          );

                          // 🔥 reload progress
                          await loadProgress();
                          await loadWarmupStatus();
                        },
                      ),
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