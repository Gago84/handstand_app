import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/routine.dart';

class RoutineService {
  RoutineService({FirebaseFirestore? firestore}) : _db = firestore;

  final FirebaseFirestore? _db;

  Future<RoutinePlan> loadPlan() async {
    final db = _db ?? FirebaseFirestore.instance;
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
    final steps = <RoutineSessionStep>[];
    final categoryItems = _filterItemsForDay(day, availableItems);
    final matchedRoutineItems =
        <({String name, List<RoutineExerciseItem> items})>[];

    for (final itemName in day.items) {
      if (_isHandstandDay(day) && _isWarmUpItem(itemName)) continue;

      final matchedItems = _matchRoutineItem(itemName, categoryItems);
      if (matchedItems.isEmpty) continue;
      matchedRoutineItems.add((name: itemName, items: matchedItems));
    }

    if (_isHandstandDay(day)) {
      _addHandstandWarmUpSteps(steps);
    }
    _addCircuitOrderedSteps(day, matchedRoutineItems, steps);

    return steps;
  }

  bool _isHandstandDay(RoutineDay day) {
    return day.title.toLowerCase().contains('handstand');
  }

  bool _isWarmUpItem(String itemName) {
    return _normalize(itemName).contains('warmup');
  }

  void _addHandstandWarmUpSteps(List<RoutineSessionStep> steps) {
    const warmUps = [
      (
        id: 'warmUpWrist',
        title: 'Warm up wrist',
        description: 'Prepare the wrists before handstand training.',
        videoUrl: 'assets/video/HS-warmUp-wrist.mp4',
      ),
      (
        id: 'warmUpShoulder',
        title: 'Warm up shoulder',
        description: 'Prepare the shoulders before handstand training.',
        videoUrl: 'assets/video/HS-warmUp-Shoulder.mp4',
      ),
    ];

    for (final warmUp in warmUps) {
      steps.add(
        RoutineSessionStep(
          item: RoutineExerciseItem(
            id: warmUp.id,
            title: warmUp.title,
            description: warmUp.description,
            durationSeconds: 60,
            videoId: '',
            videoUrl: warmUp.videoUrl,
            categoryId: 'freeHandstand',
          ),
          title: warmUp.title,
          setNumber: 1,
          totalSets: 1,
          durationSeconds: 60,
          effortLabel: '60s',
          restSeconds: 0,
          isTimed: true,
        ),
      );
    }
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
        steps.add(
          RoutineSessionStep(
            item: item,
            title: _displayTitle(matched.name),
            setNumber: set,
            totalSets: day.sets,
            durationSeconds: isTimed
                ? (item.durationSeconds > 0
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

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}
