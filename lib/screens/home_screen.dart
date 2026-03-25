import 'package:flutter/material.dart';
import '../data/firestore_service.dart';
import '../models/exercise.dart';
import 'exercise_detail_screen.dart';
import 'about_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/banner_ad_widget.dart';
import 'subscription_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🔥 ADD THIS
import '../services/progress_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isSubscribed = false;

  // 🔥 ADD THIS
  bool warmupDone = false;

  @override
  void initState() {
    super.initState();

    print("🔥 initState called");

    loadSubscription();
    loadWarmupStatus(); // 🔥 ADD THIS
  }

  Future<void> loadSubscription() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool('isSubscribed') ?? false;

    setState(() {
      isSubscribed = value;
    });
  }

  // 🔥 ADD THIS FUNCTION
  Future<void> loadWarmupStatus() async {
    final done = await ProgressService.isDone("warmup_done");
    setState(() {
      warmupDone = done;
    });
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

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];

              // 🔥 LOCK LOGIC
              final isLocked = !warmupDone && index != 0;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),

                color: isLocked
                    ? Colors.grey[300] // 🔥 màu lock
                    : Colors.white,

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
                        ? "Complete Warm Up first 🔒"
                        : (exercise.description.isEmpty
                            ? "Tap to view video"
                            : exercise.description),
                    style: TextStyle(
                      color: isLocked ? Colors.red : null,
                    ),
                  ),

                  trailing: Icon(
                    isLocked
                        ? Icons.lock
                        : Icons.arrow_forward_ios,
                  ),

            onTap: isLocked
                ? null
                : () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ExerciseDetailScreen(exercise: exercise),
                      ),
                    );

                    // 🔥 QUAN TRỌNG: reload lại
                    loadWarmupStatus();
                  },
                ),
              );
            },
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