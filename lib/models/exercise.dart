class Exercise {
  final String id;
  final String title;
  final String description;
  final String videoPortrait;
  final String videoLand;
  final int order;

  Exercise({
    required this.id,
    required this.title,
    required this.description,
    required this.videoPortrait,
    required this.videoLand,
    required this.order,
  });

  factory Exercise.fromFirestore(String id, Map<String, dynamic> data) {
    return Exercise(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      videoPortrait: data['VideoPortraitScreen'] ?? '',
      videoLand: data['VideoLandScreen'] ?? '',
      order: data['order'] ?? 0,
    );
  }
}