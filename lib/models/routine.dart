class RoutineDay {
  const RoutineDay({
    required this.key,
    required this.title,
    required this.label,
    required this.index,
    required this.items,
    required this.sets,
    required this.rep,
    required this.restSeconds,
    required this.isRestDay,
  });

  final String key;
  final String title;
  final String label;
  final int index;
  final List<String> items;
  final int sets;
  final String rep;
  final int restSeconds;
  final bool isRestDay;

  factory RoutineDay.fromMap(Map<String, dynamic> data) {
    final prescription = Map<String, dynamic>.from(
      data['prescription'] as Map? ?? const {},
    );
    final key = data['key']?.toString() ?? '';
    final title =
        data['title_en']?.toString() ?? data['title']?.toString() ?? '';

    return RoutineDay(
      key: key,
      title: title,
      label: data['label_en']?.toString() ?? '',
      index: _readInt(data['index']),
      items: (data['items'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      sets: _readInt(prescription['set'], fallback: 1),
      rep: prescription['rep']?.toString() ?? '',
      restSeconds: _restSecondsForDay(
        key: key,
        title: title,
        value: prescription['rest']?.toString() ?? '',
      ),
      isRestDay: data['rest'] == true,
    );
  }
}

class RoutineExerciseItem {
  const RoutineExerciseItem({
    required this.id,
    required this.title,
    required this.description,
    required this.durationSeconds,
    required this.videoId,
    required this.videoUrl,
    required this.categoryId,
  });

  final String id;
  final String title;
  final String description;
  final int durationSeconds;
  final String videoId;
  final String videoUrl;
  final String categoryId;

  factory RoutineExerciseItem.fromMap({
    required String id,
    required String categoryId,
    required Map<String, dynamic> data,
  }) {
    final hostedVideoUrl =
        data['videoShortUrl']?.toString() ??
        data['videoUrl']?.toString() ??
        data['video_url']?.toString() ??
        '';

    return RoutineExerciseItem(
      id: id,
      categoryId: categoryId,
      title: data['title_en']?.toString() ?? data['title']?.toString() ?? id,
      description: data['description_en']?.toString() ?? '',
      durationSeconds: _readInt(data['durationSeconds']),
      videoId: hostedVideoUrl.isEmpty
          ? data['youtubeId']?.toString() ??
                data['videoId']?.toString() ??
                data['VideoPortraitScreen']?.toString() ??
                data['VideoLandScreen']?.toString() ??
                ''
          : '',
      videoUrl: hostedVideoUrl,
    );
  }
}

class RoutinePlan {
  const RoutinePlan({required this.days, required this.exerciseItems});

  // Set this to a DateTime weekday only for temporary routine testing.
  static const int? debugWeekdayOverride = null;

  final List<RoutineDay> days;
  final List<RoutineExerciseItem> exerciseItems;

  RoutineDay get today {
    final todayIndex =
        debugWeekdayOverride ?? _routineIndexForDate(DateTime.now());
    return days.firstWhere(
      (day) => day.index == todayIndex,
      orElse: () => days.isNotEmpty
          ? days.first
          : const RoutineDay(
              key: '',
              title: 'Rest',
              label: '',
              index: 0,
              items: [],
              sets: 1,
              rep: '',
              restSeconds: 0,
              isRestDay: true,
            ),
    );
  }
}

class RoutineSessionStep {
  const RoutineSessionStep({
    required this.item,
    required this.title,
    required this.setNumber,
    required this.totalSets,
    required this.durationSeconds,
    required this.effortLabel,
    required this.restSeconds,
    required this.isTimed,
  });

  final RoutineExerciseItem item;
  final String title;
  final int setNumber;
  final int totalSets;
  final int durationSeconds;
  final String effortLabel;
  final int restSeconds;
  final bool isTimed;
}

int _routineIndexForDate(DateTime date) {
  return date.weekday;
}

int _readInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

int _parseSeconds(String value) {
  final match = RegExp(r'(\d+)').firstMatch(value);
  return int.tryParse(match?.group(1) ?? '') ?? 0;
}

int _restSecondsForDay({
  required String key,
  required String title,
  required String value,
}) {
  final normalizedTitle = title.toLowerCase();
  if (key == 'sunday' || normalizedTitle.contains('handstand')) {
    return 60;
  }

  return _parseSeconds(value);
}
