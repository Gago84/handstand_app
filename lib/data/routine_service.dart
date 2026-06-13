import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/routine.dart';

enum RoutineLevel {
  beginner('Beginner'),
  intermediate('Intermediate'),
  advance('Advance');

  const RoutineLevel(this.label);

  final String label;

  static RoutineLevel fromName(String value) {
    final normalized = value.toLowerCase();
    return RoutineLevel.values.firstWhere(
      (level) => level.name == normalized,
      orElse: () => RoutineLevel.beginner,
    );
  }
}

class RoutineService {
  RoutineService({FirebaseFirestore? firestore}) : _db = firestore;

  final FirebaseFirestore? _db;

  Future<RoutinePlan> loadPlan({
    RoutineLevel level = RoutineLevel.beginner,
  }) async {
    if (_db == null) return _localPlan(level);

    final db = _db;
    final routineDoc = await db.collection('exercises').doc('routine').get();
    final routineData = routineDoc.data() ?? const <String, dynamic>{};
    final days =
        (routineData['days'] as List? ?? const [])
            .whereType<Map>()
            .map((day) => RoutineDay.fromMap(Map<String, dynamic>.from(day)))
            .toList()
          ..sort((a, b) => a.index.compareTo(b.index));

    final categories = await db.collection('exercises').get();
    final items = <RoutineExerciseItem>[];

    for (final category in categories.docs) {
      if (category.id == 'routine') continue;

      final groups = await category.reference.collection('groups').get();
      for (final group in groups.docs) {
        final itemDocs = await group.reference.collection('items').get();
        for (final itemDoc in itemDocs.docs) {
          items.add(
            RoutineExerciseItem.fromMap(
              id: itemDoc.id,
              categoryId: category.id,
              data: itemDoc.data(),
            ),
          );
        }
      }
    }

    return RoutinePlan(days: days, exerciseItems: items);
  }

  List<RoutineSessionStep> buildSessionSteps(
    RoutineDay day,
    List<RoutineExerciseItem> availableItems,
  ) {
    if (day.isRestDay) return const [];
    if (day.detailedItems.isNotEmpty) return _buildDetailedSessionSteps(day);

    final steps = <RoutineSessionStep>[];
    final categoryItems = _filterItemsForDay(day, availableItems);
    final matchedRoutineItems =
        <({String name, List<RoutineExerciseItem> items})>[];
    final hasWarmUp = day.items.any(_isWarmUpItem);
    final hasCooldown = day.items.any(_isCooldownItem);

    for (final itemName in day.items) {
      if (_isPreparationItem(itemName)) continue;

      final matchedItems = _matchRoutineItem(itemName, categoryItems);
      if (matchedItems.isEmpty) continue;
      matchedRoutineItems.add((name: itemName, items: matchedItems));
    }

    if (hasWarmUp) _addPreparationStep(steps, _legacyWarmUp);
    _addCircuitOrderedSteps(day, matchedRoutineItems, steps);
    if (hasCooldown) _addPreparationStep(steps, _legacyCooldown);

    return steps;
  }

  List<RoutineSessionStep> _buildDetailedSessionSteps(RoutineDay day) {
    final steps = <RoutineSessionStep>[];
    final preparationItems = day.detailedItems
        .where((item) => _isPreparationItem(item.name))
        .toList(growable: false);
    final workoutItems = day.detailedItems
        .where((item) => !_isPreparationItem(item.name))
        .toList(growable: false);
    final warmUpItems = preparationItems
        .where((item) => _isWarmUpItem(item.name))
        .toList(growable: false);
    final cooldownItems = preparationItems
        .where((item) => _isCooldownItem(item.name))
        .toList(growable: false);

    for (final planItem in warmUpItems) {
      steps.add(_detailedStep(day, planItem, 1));
    }

    final maxSets = workoutItems.fold<int>(
      0,
      (maxSets, item) => item.sets > maxSets ? item.sets : maxSets,
    );

    for (var set = 1; set <= maxSets; set++) {
      for (final planItem in workoutItems) {
        if (set <= planItem.sets) {
          steps.add(_detailedStep(day, planItem, set));
        }
      }
    }

    for (final planItem in cooldownItems) {
      steps.add(_detailedStep(day, planItem, 1));
    }

    return steps;
  }

  RoutineSessionStep _detailedStep(
    RoutineDay day,
    RoutinePlanItem planItem,
    int set,
  ) {
    return RoutineSessionStep(
      item: RoutineExerciseItem(
        id: _normalize(planItem.name),
        title: planItem.name,
        description: '',
        durationSeconds: planItem.durationSeconds,
        videoId: '',
        videoUrl: planItem.videoUrl,
        categoryId: day.key,
      ),
      title: planItem.name,
      setNumber: set,
      totalSets: planItem.sets,
      durationSeconds: planItem.durationSeconds,
      effortLabel: planItem.effortLabel,
      restSeconds: planItem.restSeconds,
      isTimed: planItem.isTimed,
    );
  }

  bool _isWarmUpItem(String itemName) {
    return _normalize(itemName).contains('warmup');
  }

  bool _isCooldownItem(String itemName) {
    return _normalize(itemName).contains('cooldown');
  }

  bool _isPreparationItem(String itemName) {
    return _isWarmUpItem(itemName) || _isCooldownItem(itemName);
  }

  void _addPreparationStep(
    List<RoutineSessionStep> steps,
    ({String id, String title, String description, String videoUrl})
    preparation,
  ) {
    steps.add(
      RoutineSessionStep(
        item: RoutineExerciseItem(
          id: preparation.id,
          title: preparation.title,
          description: preparation.description,
          durationSeconds: 180,
          videoId: '',
          videoUrl: preparation.videoUrl,
          categoryId: 'preparation',
        ),
        title: preparation.title,
        setNumber: 1,
        totalSets: 1,
        durationSeconds: 180,
        effortLabel: '180s',
        restSeconds: 0,
        isTimed: true,
      ),
    );
  }

  void _addCircuitOrderedSteps(
    RoutineDay day,
    List<({String name, List<RoutineExerciseItem> items})> matchedRoutineItems,
    List<RoutineSessionStep> steps,
  ) {
    for (var set = 1; set <= day.sets; set++) {
      for (final matched in matchedRoutineItems) {
        final item = matched.items[(set - 1) % matched.items.length];
        final isTimed = _isTimedPrescription(day.rep);
        final shouldUseDayDuration = _isTuesdayDay(day);
        steps.add(
          RoutineSessionStep(
            item: item,
            title: _displayTitle(matched.name),
            setNumber: set,
            totalSets: day.sets,
            durationSeconds: isTimed
                ? (shouldUseDayDuration
                      ? _durationFromRep(day.rep)
                      : item.durationSeconds > 0
                      ? item.durationSeconds
                      : _durationFromRep(day.rep))
                : 0,
            effortLabel: _effortLabel(day.rep),
            restSeconds: day.restSeconds,
            isTimed: isTimed,
          ),
        );
      }
    }
  }

  List<RoutineExerciseItem> _filterItemsForDay(
    RoutineDay day,
    List<RoutineExerciseItem> availableItems,
  ) {
    final title = day.title.toLowerCase();
    final categoryId = switch (title) {
      final value when value.contains('lower') => 'lowerBody',
      final value when value.contains('core') => 'core',
      final value when value.contains('joint') => 'coolDown',
      final value when value.contains('upper') => 'upperBody',
      final value when value.contains('handstand') => 'freeHandstand',
      _ => '',
    };

    if (categoryId.isEmpty) return availableItems;

    return availableItems
        .where((item) => item.categoryId == categoryId)
        .toList();
  }

  List<RoutineExerciseItem> _matchRoutineItem(
    String routineName,
    List<RoutineExerciseItem> availableItems,
  ) {
    final normalized = _normalize(routineName);

    final manualMatch = _manualMatch(normalized, availableItems);
    if (manualMatch != null) return [manualMatch];

    if (normalized.contains('regularlongplank') ||
        normalized.contains('hollowbody')) {
      return [
        _findByIdOrTitle(availableItems, 'plank'),
        _findByIdOrTitle(availableItems, 'hollow'),
      ].whereType<RoutineExerciseItem>().toList();
    }

    final match = availableItems.where((item) {
      final title = _normalize(item.title);
      final id = _normalize(item.id);
      return normalized.contains(title) ||
          title.contains(normalized) ||
          normalized.contains(id) ||
          id.contains(normalized);
    }).toList();

    if (match.isNotEmpty) return [match.first];

    final firstWord = normalized.split(RegExp(r'(?=[A-Z])|[^a-z0-9]+')).first;
    return availableItems
        .where((item) => _normalize(item.title).contains(firstWord))
        .take(1)
        .toList();
  }

  RoutineExerciseItem? _manualMatch(
    String normalized,
    List<RoutineExerciseItem> availableItems,
  ) {
    if (normalized.contains('side') && normalized.contains('plank')) {
      final sidePlankQueries = [
        if (normalized.contains('right')) 'rightsideplank',
        if (normalized.contains('left')) 'leftsideplank',
        'sideplank',
      ];

      for (final query in sidePlankQueries) {
        final exactMatch = _findExactByIdOrTitle(availableItems, query);
        if (exactMatch != null) return exactMatch;
      }

      for (final query in sidePlankQueries) {
        final match = _findByIdOrTitle(availableItems, query);
        if (match != null && _normalize(match.title) != 'plank') {
          return match;
        }
      }

      return _findExactByIdOrTitle(availableItems, 'plank');
    }

    final id = switch (normalized) {
      final value when value.contains('quad') && value.contains('split') =>
        'bungarianSplit',
      final value when value.contains('glute') && value.contains('bridge') =>
        'gluteBridge',
      final value when value.contains('single') && value.contains('calf') =>
        'singleCalfRaise',
      _ => null,
    };

    if (id == null) return null;

    for (final item in availableItems) {
      if (item.id == id) return item;
    }

    return null;
  }

  RoutineExerciseItem? _findExactByIdOrTitle(
    List<RoutineExerciseItem> items,
    String text,
  ) {
    final normalized = _normalize(text);
    for (final item in items) {
      if (_normalize(item.id) == normalized ||
          _normalize(item.title) == normalized) {
        return item;
      }
    }
    return null;
  }

  RoutineExerciseItem? _findByIdOrTitle(
    List<RoutineExerciseItem> items,
    String text,
  ) {
    final normalized = _normalize(text);
    for (final item in items) {
      if (_normalize(item.id).contains(normalized) ||
          _normalize(item.title).contains(normalized)) {
        return item;
      }
    }
    return null;
  }

  int _durationFromRep(String rep) {
    final match = RegExp(r'(\d+)').firstMatch(rep);
    return int.tryParse(match?.group(1) ?? '') ?? 30;
  }

  bool _isTimedPrescription(String rep) {
    final normalized = rep.toLowerCase();
    return RegExp(r'\d+\s*s(ec(ond)?s?)?\b').hasMatch(normalized);
  }

  String _effortLabel(String rep) {
    final match = RegExp(r'(\d+)').firstMatch(rep);
    final count = match?.group(1);

    if (count == null) return rep;
    if (_isTimedPrescription(rep)) return '${count}s';
    return rep;
  }

  String _displayTitle(String routineName) {
    return routineName.replaceAll('Bungarian', 'Bulgarian');
  }

  bool _isTuesdayDay(RoutineDay day) {
    final normalizedKey = _normalize(day.key);
    return day.index == DateTime.tuesday || normalizedKey.contains('tuesday');
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}

RoutinePlan _localPlan(RoutineLevel level) {
  return RoutinePlan(days: _localRoutineDays(level), exerciseItems: const []);
}

List<RoutineDay> _localRoutineDays(RoutineLevel level) {
  final days = switch (level) {
    RoutineLevel.beginner => _beginnerDays,
    RoutineLevel.intermediate => _intermediateDays,
    RoutineLevel.advance => _advanceDays,
  };

  return days;
}

RoutineDay _routineDay({
  required String key,
  required String title,
  required int index,
  required List<RoutinePlanItem> items,
}) {
  final firstWorkout = items.firstWhere(
    (item) => !_isPreparationName(item.name),
    orElse: () => items.first,
  );

  return RoutineDay(
    key: key,
    title: title,
    label: _weekdayLabel(index),
    index: index,
    items: items.map((item) => item.name).toList(growable: false),
    detailedItems: items,
    sets: firstWorkout.sets,
    rep: firstWorkout.effortLabel,
    restSeconds: firstWorkout.restSeconds,
    isRestDay: false,
  );
}

RoutineDay _restDay() {
  return const RoutineDay(
    key: 'saturday',
    title: 'Rest',
    label: 'Sat',
    index: DateTime.saturday,
    items: [],
    detailedItems: [],
    sets: 1,
    rep: '',
    restSeconds: 0,
    isRestDay: true,
  );
}

RoutinePlanItem _timed(
  String name,
  int seconds,
  int restSeconds,
  int sets,
  String videoPath,
) {
  return RoutinePlanItem(
    name: name,
    effortLabel: '${seconds}s',
    durationSeconds: seconds,
    restSeconds: restSeconds,
    sets: sets,
    isTimed: true,
    videoUrl: _storageVideoUrl(videoPath),
  );
}

RoutinePlanItem _reps(
  String name,
  String effortLabel,
  int restSeconds,
  int sets,
  String videoPath,
) {
  return RoutinePlanItem(
    name: name,
    effortLabel: effortLabel,
    durationSeconds: 0,
    restSeconds: restSeconds,
    sets: sets,
    isTimed: false,
    videoUrl: _storageVideoUrl(videoPath),
  );
}

RoutinePlanItem _warmUp([String videoPath = _sharedWarmUpAsset]) {
  return _timed('WarmUp', 180, 0, 1, videoPath);
}

RoutinePlanItem _cooldown([String videoPath = _sharedCooldownAsset]) {
  return _timed('Cooldown', 180, 0, 1, videoPath);
}

String _storageVideoUrl(String localAssetPath) {
  if (localAssetPath.startsWith('http')) return localAssetPath;

  final objectPath = localAssetPath.replaceFirst('assets/', 'exercise/');
  final encodedObjectPath = Uri.encodeComponent(objectPath);
  return 'https://firebasestorage.googleapis.com/v0/b/'
      'banana-57559.firebasestorage.app/o/$encodedObjectPath?alt=media';
}

bool _isPreparationName(String name) {
  final normalized = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  return normalized.contains('warmup') || normalized.contains('cooldown');
}

String _weekdayLabel(int index) {
  return switch (index) {
    DateTime.monday => 'Mon',
    DateTime.tuesday => 'Tue',
    DateTime.wednesday => 'Wed',
    DateTime.thursday => 'Thu',
    DateTime.friday => 'Fri',
    DateTime.saturday => 'Sat',
    DateTime.sunday => 'Sun',
    _ => '',
  };
}

const _assetRoot = 'assets/video version 1.1.0';
const _sharedWarmUpAsset = '$_assetRoot/WarmUp.mp4';
const _sharedCooldownAsset = '$_assetRoot/CoolDown.mp4';

const _beginner = '$_assetRoot/Beginner';
const _intermediate = '$_assetRoot/Intermediate';
const _advance = '$_assetRoot/Advance';

final _beginnerDays = [
  _routineDay(
    key: 'monday',
    title: 'Upper (push day)',
    index: DateTime.monday,
    items: [
      _warmUp(),
      _reps('Pike pushup', '5 reps', 60, 3, '$_beginner/2_Mon_Pike pushup.mp4'),
      _reps(
        'Regular pushup',
        '5-10 reps',
        60,
        3,
        '$_beginner/2_Mon-Regular push up.mp4',
      ),
      _reps(
        'Diamond pushup',
        '5-10 reps',
        60,
        3,
        '$_beginner/2_Mon-Diamond pushup.mp4',
      ),
      _cooldown(),
    ],
  ),
  _routineDay(
    key: 'tuesday',
    title: 'Core',
    index: DateTime.tuesday,
    items: [
      _warmUp(),
      _timed('Regular plank', 30, 60, 3, '$_beginner/3_Tue- Regular Plank.mp4'),
      _timed('Hollow body', 30, 60, 3, '$_beginner/3_Tue-Hollow Body.mp4'),
      _timed(
        'Right Side plank',
        30,
        60,
        3,
        '$_beginner/3_Tue-Right Side Plank.mp4',
      ),
      _timed(
        'Left side plank',
        30,
        60,
        3,
        '$_beginner/3_Tue-Left Side Plank.mp4',
      ),
      _timed('Arch Up', 30, 60, 3, '$_beginner/3_Tue-Arch up.mp4'),
      _cooldown(),
    ],
  ),
  _routineDay(
    key: 'wednesday',
    title: 'Lower',
    index: DateTime.wednesday,
    items: [
      _warmUp(),
      _reps(
        'Right Bulgarian split',
        '5-10 reps',
        15,
        3,
        '$_beginner/4_Wed-Right Bulgarian split.mp4',
      ),
      _reps(
        'Left Bulgarian split',
        '5-10 reps',
        15,
        3,
        '$_beginner/4_Wed-Left Bulgarian split.mp4',
      ),
      _reps(
        'Glute bridge',
        '5-10 reps',
        15,
        3,
        '$_beginner/4_Wed-Glute Bridge.mp4',
      ),
      _reps(
        'Right Single Calf raise',
        '5-10 reps',
        15,
        3,
        '$_beginner/4_Wed-Right single Calf.mp4',
      ),
      _reps(
        'Left Single Calf raise',
        '5-10 reps',
        15,
        3,
        '$_beginner/4_Wed-Left single Calf.mp4',
      ),
      _cooldown(),
    ],
  ),
  _routineDay(
    key: 'thursday',
    title: 'Joints',
    index: DateTime.thursday,
    items: [
      _warmUp(),
      _timed('Overhead rod', 60, 30, 3, '$_beginner/5_Thus-Overhead Rod.mp4'),
      _timed(
        'Dynamic Bridge',
        60,
        30,
        3,
        '$_beginner/5_Thus-Dynamic Bridge.mp4',
      ),
      _timed('DownDog', 60, 30, 3, '$_beginner/5_Thus-DownDog.mp4'),
      _timed('Squat', 60, 30, 3, '$_beginner/5_Thus-Squat.mp4'),
      _timed('Lunge', 60, 30, 3, '$_beginner/5_Thus-Lunge.mp4'),
      _timed('Catcow', 60, 30, 3, '$_beginner/5_Thus-Cat Cow.mp4'),
      _cooldown(),
    ],
  ),
  _routineDay(
    key: 'friday',
    title: 'Upper (pull day)',
    index: DateTime.friday,
    items: [
      _warmUp(),
      _reps(
        'Regular Pull up',
        '5-10 reps',
        60,
        3,
        '$_beginner/6_Fri-Regular Pull up.mp4',
      ),
      _reps(
        'Row (table)',
        '5-10 reps',
        60,
        3,
        '$_beginner/6_Fri-Row (table).mp4',
      ),
      _reps(
        'Regular Chin up',
        '5-10 reps',
        60,
        3,
        '$_beginner/6_Fri-Regular Chin up.mp4',
      ),
      _cooldown(),
    ],
  ),
  _restDay(),
  _routineDay(
    key: 'sunday',
    title: 'Handstand training',
    index: DateTime.sunday,
    items: [
      _warmUp('$_beginner/Sunday-WarmUp.mp4'),
      _timed('Back to wall', 60, 60, 3, '$_beginner/Sunday-BackToWall.mp4'),
      _timed('Face to wall', 60, 60, 3, '$_beginner/Sunday-FaceToWall.mp4'),
      _timed('Exit', 60, 60, 3, '$_beginner/Sunday-Exit.mp4'),
      _timed('Free', 60, 60, 3, '$_beginner/Sunday-Free.mp4'),
      _cooldown('$_beginner/Sunday-CoolDown.mp4'),
    ],
  ),
];

final _intermediateDays = [
  _routineDay(
    key: 'monday',
    title: 'Upper (push day)',
    index: DateTime.monday,
    items: [
      _warmUp(),
      _reps(
        'Pike pushup',
        '10 reps',
        60,
        3,
        '$_intermediate/2_Mon_Pike pushup.mp4',
      ),
      _reps(
        'Archer pushup',
        '10 reps',
        60,
        3,
        '$_intermediate/2_Mon-Archer pushup.mp4',
      ),
      _reps(
        'Diamond pushup',
        '10 reps',
        60,
        3,
        '$_intermediate/2_Mon-Diamond push up.mp4',
      ),
      _cooldown(),
    ],
  ),
  _routineDay(
    key: 'tuesday',
    title: 'Core',
    index: DateTime.tuesday,
    items: [
      _warmUp(),
      _timed('Elbow plank', 60, 60, 3, '$_intermediate/3_Tue-Elbow Plank.mp4'),
      _timed('Hollow body', 60, 60, 3, '$_intermediate/3_Tue-Hollow Body.mp4'),
      _timed(
        'Right Side plank',
        60,
        60,
        3,
        '$_intermediate/3_Tue-Right Side Plank.mp4',
      ),
      _timed(
        'Left side plank',
        60,
        60,
        3,
        '$_intermediate/3_Tue-Left Side Plank.mp4',
      ),
      _timed('Arch Up', 60, 60, 3, '$_intermediate/3_Tue-Arch up.mp4'),
      _cooldown(),
    ],
  ),
  _routineDay(
    key: 'wednesday',
    title: 'Lower',
    index: DateTime.wednesday,
    items: [
      _warmUp(),
      _reps(
        'Right Bulgarian split',
        '10 reps',
        10,
        3,
        '$_intermediate/4_Wed-Right Bulgarian split.mp4',
      ),
      _reps(
        'Left Bulgarian split',
        '10 reps',
        10,
        3,
        '$_intermediate/4_Wed-Left Bulgarian split.mp4',
      ),
      _reps(
        'Right leg glute bridge',
        '10 reps',
        10,
        3,
        '$_intermediate/4_Wed-Right leg Bridge.mp4',
      ),
      _reps(
        'Left leg glute bridge',
        '10 reps',
        10,
        3,
        '$_intermediate/4_Wed-Left leg Bridge.mp4',
      ),
      _reps(
        'Right Single Calf raise',
        '10 reps',
        10,
        3,
        '$_intermediate/4_Wed-Right single Calf.mp4',
      ),
      _reps(
        'Left Single Calf raise',
        '10 reps',
        10,
        3,
        '$_intermediate/4_Wed-Left single Calf.mp4',
      ),
      _cooldown(),
    ],
  ),
  _routineDay(
    key: 'thursday',
    title: 'Joints',
    index: DateTime.thursday,
    items: [
      _warmUp(),
      _timed(
        'Overhead rod',
        60,
        10,
        3,
        '$_intermediate/5_Thus-Overhead Rod.mp4',
      ),
      _timed(
        'Static Bridge',
        30,
        10,
        3,
        '$_intermediate/5_Thus-Static Bridge1.mp4',
      ),
      _timed('DownDog', 60, 10, 3, '$_intermediate/5_Thus-DownDog.mp4'),
      _timed('Deep squat', 60, 10, 3, '$_intermediate/5_Thus-Deep Squat.mp4'),
      _timed('Lunge', 60, 10, 3, '$_intermediate/5_Thus-Lunge.mp4'),
      _timed(
        'Finger to ground',
        60,
        10,
        3,
        '$_intermediate/5_Thus-Finger to Ground.mp4',
      ),
      _timed('Catcow', 60, 10, 3, '$_intermediate/5_Thus-Cat Cow.mp4'),
      _cooldown(),
    ],
  ),
  _routineDay(
    key: 'friday',
    title: 'Upper (pull day)',
    index: DateTime.friday,
    items: [
      _warmUp(),
      _reps(
        'Archer Pull up',
        '10 reps',
        60,
        3,
        '$_intermediate/6_Fri-Archer Pull up.mp4',
      ),
      _reps(
        'Chest to Bar pull up',
        '10 reps',
        60,
        3,
        '$_intermediate/6_Fri-Chest to Bar Pull up.mp4',
      ),
      _reps(
        'Archer Row',
        '10 reps',
        60,
        3,
        '$_intermediate/6_Fri-Archer Row.mp4',
      ),
      _reps(
        'Archer Chin up',
        '10 reps',
        60,
        3,
        '$_intermediate/6_Fri-Archer Chin up.mp4',
      ),
      _cooldown(),
    ],
  ),
  _restDay(),
  _routineDay(
    key: 'sunday',
    title: 'Handstand training',
    index: DateTime.sunday,
    items: [
      _warmUp('$_intermediate/Sunday-WarmUp.mp4'),
      _timed('Face to wall', 60, 30, 3, '$_intermediate/Sunday-FaceToWall.mp4'),
      _timed('Free', 60, 30, 3, '$_intermediate/Sunday-Free.mp4'),
      _cooldown('$_intermediate/Sunday-CoolDown.mp4'),
    ],
  ),
];

final _advanceDays = [
  _routineDay(
    key: 'monday',
    title: 'Upper (push day)',
    index: DateTime.monday,
    items: [
      _warmUp(),
      _reps(
        'Wall handstand pushup',
        '10 reps',
        60,
        3,
        '$_advance/2_Mon-Wall Handstand Pushup.mp4',
      ),
      _reps(
        'One left hand pushup',
        '3-5 reps',
        0,
        3,
        '$_advance/2_Mon-One left hand Pushup.mp4',
      ),
      _reps(
        'One right hand pushup',
        '3-5 reps',
        60,
        3,
        '$_advance/2_Mon-One right hand Pushup.mp4',
      ),
      _reps(
        'Diamond pushup',
        '15 reps',
        60,
        3,
        '$_advance/2_Mon-Diamond pushup.mp4',
      ),
      _cooldown(),
    ],
  ),
  _routineDay(
    key: 'tuesday',
    title: 'Core',
    index: DateTime.tuesday,
    items: [
      _warmUp(),
      _timed('Wrist plank', 60, 60, 3, '$_advance/3_Tue-Wrist Plank.mp4'),
      _timed('Hollow body', 60, 60, 3, '$_advance/3_Tue-Hollow Body.mp4'),
      _timed(
        'Right Side plank',
        60,
        60,
        3,
        '$_advance/3_Tue-Right Side Plank.mp4',
      ),
      _timed(
        'Left side plank',
        60,
        60,
        3,
        '$_advance/3_Tue-Left Side Plank.mp4',
      ),
      _timed('Arch Up', 60, 60, 3, '$_advance/3_Tue-Arch up.mp4'),
      _cooldown(),
    ],
  ),
  _routineDay(
    key: 'wednesday',
    title: 'Lower',
    index: DateTime.wednesday,
    items: [
      _warmUp(),
      _reps(
        'Archer Squat',
        '10 reps',
        30,
        3,
        '$_advance/4_Wed-Archer Squat.mp4',
      ),
      _reps(
        'Left Pistol Squat',
        '5 reps',
        30,
        3,
        '$_advance/4_Wed-Left Pistol Squat.mp4',
      ),
      _reps(
        'Right Pistol Squat',
        '5 reps',
        30,
        3,
        '$_advance/4_Wed-Right Pistol Squat.mp4',
      ),
      _cooldown(),
    ],
  ),
  _routineDay(
    key: 'thursday',
    title: 'Joints',
    index: DateTime.thursday,
    items: [
      _warmUp(),
      _timed('Overhead rod', 60, 10, 3, '$_advance/5_Thus-Overhead Rod.mp4'),
      _timed(
        'Static invert Plank',
        60,
        10,
        3,
        '$_advance/5_Thus-Static Invert Plank.mp4',
      ),
      _timed('DownDog', 60, 10, 3, '$_advance/5_Thus-DownDog.mp4'),
      _timed('Deep Squat', 60, 10, 3, '$_advance/5_Thus-Deep Squat.mp4'),
      _timed('Lunge', 60, 10, 3, '$_advance/5_Thus-Lunge.mp4'),
      _timed(
        'Palm to ground',
        60,
        10,
        3,
        '$_advance/5_Thus-Palm to Ground.mp4',
      ),
      _timed('Catcow', 60, 10, 3, '$_advance/5_Thus-Cat Cow.mp4'),
      _cooldown(),
    ],
  ),
  _routineDay(
    key: 'friday',
    title: 'Upper (pull day)',
    index: DateTime.friday,
    items: [
      _warmUp(),
      _reps(
        'One left Hand Pull up (Support)',
        '10 reps',
        30,
        3,
        '$_advance/6_Fri-One left hand pull up (support).mp4',
      ),
      _reps(
        'One Right Hand Pull up (Support)',
        '10 reps',
        30,
        3,
        '$_advance/6_Fri-One right hand pull up (support).mp4',
      ),
      _reps(
        'Archer high pull up',
        '10 reps',
        30,
        3,
        '$_advance/6_Fri-Archer high pull up.mp4',
      ),
      _cooldown(),
    ],
  ),
  _restDay(),
  _routineDay(
    key: 'sunday',
    title: 'Handstand training',
    index: DateTime.sunday,
    items: [
      _warmUp('$_advance/Sunday-WarmUp.mp4'),
      _reps(
        'Free handstand negative pushup',
        '5-10 reps',
        60,
        3,
        '$_advance/Sunday-Negative Free Handstand.mp4',
      ),
      _reps(
        'Free handstand pushup',
        '5-10 reps',
        60,
        3,
        '$_advance/Sunday-Free Handstand Pushup.mp4',
      ),
      _cooldown('$_advance/Sunday-CoolDown.mp4'),
    ],
  ),
];

const _legacyWarmUp = (
  id: 'warmUpCombined',
  title: 'Warm Up',
  description: 'Prepare your body before the training session.',
  videoUrl:
      'https://firebasestorage.googleapis.com/v0/b/banana-57559.firebasestorage.app/o/exercise%2Fpreparation%2FWarmUp-Combine.mp4?alt=media&token=A1186708-E030-4395-AD8F-3C4D7694F2F2',
);

const _legacyCooldown = (
  id: 'cooldownCombined',
  title: 'Cooldown',
  description: 'Cool down after the training session.',
  videoUrl:
      'https://firebasestorage.googleapis.com/v0/b/banana-57559.firebasestorage.app/o/exercise%2Fpreparation%2FCoolDown-Combine.mp4?alt=media&token=1648EEB6-64D4-4B18-8267-6F7F1D8E4D7B',
);
