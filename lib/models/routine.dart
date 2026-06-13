class RoutineDay {
  const RoutineDay({
    required this.key,
    required this.title,
    required this.label,
    required this.index,
    required this.items,
    this.detailedItems = const [],
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
  final List<RoutinePlanItem> detailedItems;
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
      items: _normalizeRoutineItems(data['items'] as List? ?? const []),
      detailedItems: const [],
      sets: _readInt(prescription['set'], fallback: 1),
      rep: _repForDay(
        key: key,
        title: title,
        index: _readInt(data['index']),
        value: prescription['rep']?.toString() ?? '',
      ),
      restSeconds: _restSecondsForDay(
        key: key,
        title: title,
        index: _readInt(data['index']),
        value: prescription['rest']?.toString() ?? '',
      ),
      isRestDay: data['rest'] == true,
    );
  }
}

class RoutinePlanItem {
  const RoutinePlanItem({
    required this.name,
    required this.effortLabel,
    required this.durationSeconds,
    required this.restSeconds,
    required this.sets,
    required this.isTimed,
    required this.videoUrl,
  });

  final String name;
  final String effortLabel;
  final int durationSeconds;
  final int restSeconds;
  final int sets;
  final bool isTimed;
  final String videoUrl;
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
              detailedItems: [],
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

List<String> _normalizeRoutineItems(List items) {
  final normalizedItems = <String>[];
  for (final item in items) {
    final name = item.toString();
    if (_normalizeText(name).contains('eachsideplank')) {
      normalizedItems.addAll(const ['Right side plank', 'Left side plank']);
    } else {
      normalizedItems.add(name);
    }
  }
  return normalizedItems;
}

String _repForDay({
  required String key,
  required String title,
  required int index,
  required String value,
}) {
  if (_isTuesday(key: key, index: index) &&
      RegExp(r'\d+\s*s(ec(ond)?s?)?\b', caseSensitive: false).hasMatch(value)) {
    return '60s';
  }
  return value;
}

int _restSecondsForDay({
  required String key,
  required String title,
  required int index,
  required String value,
}) {
  if (_isTuesday(key: key, index: index)) {
    final sourceSeconds = _parseSeconds(value);
    return sourceSeconds > 0 ? 30 : 0;
  }

  return _parseSeconds(value);
}

bool _isTuesday({required String key, required int index}) {
  final normalizedKey = _normalizeText(key);
  return index == DateTime.tuesday || normalizedKey.contains('tuesday');
}

String _normalizeText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}
