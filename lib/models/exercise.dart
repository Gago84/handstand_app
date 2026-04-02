class ExerciseStep {
  final String instruction;
  final int duration;

  ExerciseStep({
    required this.instruction,
    required this.duration,
  });

  factory ExerciseStep.fromMap(Map<String, dynamic> data) {
    return ExerciseStep(
      instruction: data['instruction'] ?? '',
      duration: data['duration'] ?? 0,
    );
  }
}

class Exercise {
  final String id;
  final String title;
  final String description;
  final String videoPortrait;
  final String videoLand;
  final List<ExerciseStep> steps;
  final int order;

  Exercise({
    required this.id,
    required this.title,
    required this.description,
    required this.videoPortrait,
    required this.videoLand,
    required this.steps,
    required this.order,
  });

  factory Exercise.fromFirestore(String id, Map<String, dynamic> data) {
    final rawSteps = data['steps'];
    final steps = rawSteps is List
        ? rawSteps
            .whereType<Map>()
            .map((step) => ExerciseStep.fromMap(
                  Map<String, dynamic>.from(step),
                ))
            .toList()
        : <ExerciseStep>[];

    return Exercise(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      videoPortrait: data['VideoPortraitScreen'] ?? '',
      videoLand: data['VideoLandScreen'] ?? '',
      steps: steps,
      order: data['order'] ?? 0,
    );
  }
}
