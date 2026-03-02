import 'package:flutter/material.dart';
import '../data/exercise_data.dart';
import 'exercise_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Handstand Free"),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final exercise = exercises[index];

          return Card(
            margin: const EdgeInsets.all(12),
            child: ListTile(
              title: Text(
                exercise.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(exercise.description),
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
      ),
    );
  }
}