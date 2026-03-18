import 'package:flutter/material.dart';
import '../data/firestore_service.dart';
import '../models/exercise.dart';
import 'exercise_detail_screen.dart';
import 'about_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

      // 🔥 LOAD FIREBASE DATA
      body:StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('HandStand').orderBy('order').snapshots(),
          builder: (context, snapshot) {
            // loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // error
            if (snapshot.hasError) {
              return Center(
                child: Text("Error: ${snapshot.error}"),
              );
            }

            // empty
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("No exercises found"));
            }

            final docs = snapshot.data!.docs;

            final exercises = docs.map((doc) {
              return Exercise.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
            }).toList();

            exercises.sort((a, b) => a.order.compareTo(b.order));

            // list
            return ListView.builder(
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];

                return Card(
                  margin: const EdgeInsets.all(12),
                  child: ListTile(
                  title: Text(
                    "Step ${index + 1}: ${exercise.title}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
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
        )
    );
  }
}