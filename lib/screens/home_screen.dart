import 'package:flutter/material.dart';
import '../data/firestore_service.dart';
import '../models/exercise.dart';
import 'exercise_detail_screen.dart';
import 'about_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/banner_ad_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
        ],
      ),

      // 🔥 BODY
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
            padding: const EdgeInsets.only(bottom: 16), // 👈 nhẹ thôi
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16), // 👈 bo góc đẹp
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
                    exercise.description.isEmpty
                        ? "Tap to view video"
                        : exercise.description,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ExerciseDetailScreen(exercise: exercise),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),

      // 👇 👇 👇 QUAN TRỌNG NHẤT
      bottomNavigationBar: const SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: BannerAdWidget(),
        ),
      ),

    );
  }
}