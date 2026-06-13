import 'package:flutter_test/flutter_test.dart';
import 'package:handstand_app/data/routine_service.dart';
import 'package:handstand_app/models/routine.dart';

void main() {
  test('local routine videos use Firebase Storage download URLs', () async {
    final plan = await RoutineService().loadPlan(level: RoutineLevel.beginner);
    final monday = plan.days.firstWhere((day) => day.index == DateTime.monday);
    final steps = RoutineService().buildSessionSteps(
      monday,
      plan.exerciseItems,
    );

    expect(
      steps.first.item.videoUrl,
      startsWith(
        'https://firebasestorage.googleapis.com/v0/b/banana-57559.firebasestorage.app/o/',
      ),
    );
    expect(
      steps.first.item.videoUrl,
      contains('exercise%2Fvideo%20version%201.1.0%2FWarmUp.mp4'),
    );
    expect(
      steps[1].item.videoUrl,
      contains('Beginner%2F2_Mon_Pike%20pushup.mp4'),
    );
  });

  test('local routine uses circuit rounds for multi-set exercises', () async {
    final plan = await RoutineService().loadPlan(level: RoutineLevel.beginner);
    final monday = plan.days.firstWhere((day) => day.index == DateTime.monday);
    final steps = RoutineService().buildSessionSteps(
      monday,
      plan.exerciseItems,
    );

    expect(steps.map((step) => '${step.title} ${step.setNumber}').toList(), [
      'WarmUp 1',
      'Pike pushup 1',
      'Regular pushup 1',
      'Diamond pushup 1',
      'Pike pushup 2',
      'Regular pushup 2',
      'Diamond pushup 2',
      'Pike pushup 3',
      'Regular pushup 3',
      'Diamond pushup 3',
      'Cooldown 1',
    ]);
  });

  test('buildSessionSteps completes all exercises in each set first', () {
    const day = RoutineDay(
      key: 'day5',
      title: 'Joints',
      label: '5',
      index: 4,
      items: [
        'WarmUp',
        'Overhead rod',
        'Bridge',
        'DownDog',
        'Deep squat',
        'Lunge',
        'catcow',
        'Cooldown',
      ],
      sets: 3,
      rep: '30s',
      restSeconds: 0,
      isRestDay: false,
    );

    final availableItems = [
      _item(id: 'overheadRod', title: 'Overhead rod'),
      _item(id: 'bridge', title: 'Bridge'),
      _item(id: 'downDog', title: 'DownDog'),
      _item(id: 'deepSquat', title: 'Deep squat'),
      _item(id: 'lunge', title: 'Lunge'),
      _item(id: 'catCow', title: 'catcow'),
    ];

    final steps = RoutineService().buildSessionSteps(day, availableItems);

    expect(steps.map((step) => '${step.title} ${step.setNumber}').toList(), [
      'Warm Up 1',
      'Overhead rod 1',
      'Bridge 1',
      'DownDog 1',
      'Deep squat 1',
      'Lunge 1',
      'catcow 1',
      'Overhead rod 2',
      'Bridge 2',
      'DownDog 2',
      'Deep squat 2',
      'Lunge 2',
      'catcow 2',
      'Overhead rod 3',
      'Bridge 3',
      'DownDog 3',
      'Deep squat 3',
      'Lunge 3',
      'catcow 3',
      'Cooldown 1',
    ]);
    expect(steps.first.item.id, 'warmUpCombined');
    expect(steps.first.durationSeconds, 180);
    expect(steps.first.isTimed, isTrue);
    expect(steps.last.item.id, 'cooldownCombined');
    expect(steps.last.durationSeconds, 180);
    expect(steps.last.isTimed, isTrue);
  });

  test('buildSessionSteps adds preparation videos around Sunday handstand', () {
    const day = RoutineDay(
      key: 'sunday',
      title: 'Handstand training',
      label: 'Sunday',
      index: 7,
      items: [
        'Warm up',
        'Back to wall',
        'Face to wall',
        'Exit',
        'Free',
        'Cooldown',
      ],
      sets: 3,
      rep: '30s',
      restSeconds: 60,
      isRestDay: false,
    );

    final availableItems = [
      _handstandItem(id: 'warmUpJoints', title: 'Warm up'),
      _handstandItem(id: 'backToWall', title: 'Back to wall'),
      _handstandItem(id: 'faceToWall', title: 'Face to wall'),
      _handstandItem(id: 'exitHandstand', title: 'Exit handstand'),
      _handstandItem(id: 'freeHandstand', title: 'Free handstand'),
    ];

    final steps = RoutineService().buildSessionSteps(day, availableItems);

    expect(steps.map((step) => '${step.title} ${step.setNumber}').toList(), [
      'Warm Up 1',
      'Back to wall 1',
      'Face to wall 1',
      'Exit 1',
      'Free 1',
      'Back to wall 2',
      'Face to wall 2',
      'Exit 2',
      'Free 2',
      'Back to wall 3',
      'Face to wall 3',
      'Exit 3',
      'Free 3',
      'Cooldown 1',
    ]);
    expect(steps[0].durationSeconds, 180);
    expect(steps[0].totalSets, 1);
    expect(steps[0].restSeconds, 0);
    expect(steps[0].isTimed, isTrue);
    expect(steps[0].item.videoUrl, contains('WarmUp-Combine.mp4'));
    expect(steps[1].restSeconds, 60);
    expect(steps[1].item.videoUrl, 'https://example.com/old-web-video.mp4');
    expect(steps.last.item.videoUrl, contains('CoolDown-Combine.mp4'));
  });

  test('buildSessionSteps skips preparation videos on rest days', () {
    const day = RoutineDay(
      key: 'day7',
      title: 'Rest',
      label: '7',
      index: 6,
      items: [],
      sets: 1,
      rep: '',
      restSeconds: 0,
      isRestDay: true,
    );

    expect(RoutineService().buildSessionSteps(day, const []), isEmpty);
  });

  test('Tuesday timed duration and rest are normalized', () {
    final day = RoutineDay.fromMap({
      'key': 'tuesday',
      'title_en': 'Core',
      'index': 2,
      'items': ['WarmUp', 'Plank', 'Cooldown'],
      'prescription': {'set': 1, 'rep': '30s', 'rest': '60s'},
    });

    final steps = RoutineService().buildSessionSteps(day, [
      _item(id: 'plank', title: 'Plank', categoryId: 'core'),
    ]);

    expect(day.rep, '60s');
    expect(day.restSeconds, 30);
    expect(steps[1].durationSeconds, 60);
    expect(steps[1].effortLabel, '60s');
    expect(steps[1].restSeconds, 30);
  });

  test('other timed routine days keep their source duration and rest', () {
    final day = RoutineDay.fromMap({
      'key': 'sunday',
      'title_en': 'Handstand training',
      'index': 7,
      'items': ['Back to wall'],
      'prescription': {'set': 3, 'rep': '30s', 'rest': '120s'},
    });

    expect(day.rep, '30s');
    expect(day.restSeconds, 120);
  });

  test('each-side plank is split into right and left plank steps', () {
    final day = RoutineDay.fromMap({
      'key': 'tuesday',
      'title_en': 'Core',
      'index': 2,
      'items': ['WarmUp', 'Each Side plank', 'Cooldown'],
      'prescription': {'set': 1, 'rep': '30s', 'rest': '60s'},
    });

    final steps = RoutineService().buildSessionSteps(day, [
      _item(id: 'plank', title: 'Plank', categoryId: 'core'),
    ]);

    expect(day.items, [
      'WarmUp',
      'Right side plank',
      'Left side plank',
      'Cooldown',
    ]);
    expect(steps.map((step) => step.title).toList(), [
      'Warm Up',
      'Right side plank',
      'Left side plank',
      'Cooldown',
    ]);
    expect(steps[1].durationSeconds, 60);
    expect(steps[1].effortLabel, '60s');
    expect(steps[1].restSeconds, 30);
  });

  test('side plank steps prefer side plank videos over generic plank', () {
    final day = RoutineDay.fromMap({
      'key': 'tuesday',
      'title_en': 'Core',
      'index': 2,
      'items': ['Each Side plank'],
      'prescription': {'set': 1, 'rep': '30s', 'rest': '60s'},
    });

    final steps = RoutineService().buildSessionSteps(day, [
      _item(
        id: 'plank',
        title: 'Plank',
        categoryId: 'core',
        videoUrl: 'https://example.com/plank.mp4',
      ),
      _item(
        id: 'rightSidePlank',
        title: 'Right side plank',
        categoryId: 'core',
        videoUrl: 'https://example.com/right-side-plank.mp4',
      ),
      _item(
        id: 'leftSidePlank',
        title: 'Left side plank',
        categoryId: 'core',
        videoUrl: 'https://example.com/left-side-plank.mp4',
      ),
    ]);

    expect(steps[0].title, 'Right side plank');
    expect(steps[0].item.id, 'rightSidePlank');
    expect(steps[0].item.videoUrl, 'https://example.com/right-side-plank.mp4');
    expect(steps[1].title, 'Left side plank');
    expect(steps[1].item.id, 'leftSidePlank');
    expect(steps[1].item.videoUrl, 'https://example.com/left-side-plank.mp4');
  });

  test(
    'side plank steps fall back to generic plank when no side video exists',
    () {
      final day = RoutineDay.fromMap({
        'key': 'tuesday',
        'title_en': 'Core',
        'index': 2,
        'items': ['Each Side plank'],
        'prescription': {'set': 1, 'rep': '30s', 'rest': '60s'},
      });

      final steps = RoutineService().buildSessionSteps(day, [
        _item(id: 'plank', title: 'Plank', categoryId: 'core'),
      ]);

      expect(steps[0].item.id, 'plank');
      expect(steps[1].item.id, 'plank');
    },
  );

  test('hosted videos are streamed and cached instead of bundled', () {
    final item = RoutineExerciseItem.fromMap(
      id: 'faceToWall',
      categoryId: 'freeHandstand',
      data: {
        'title_en': 'Face to wall',
        'durationSeconds': 30,
        'VideoPortraitScreen': 'old-youtube-id',
        'videoShortUrl': 'https://example.com/old-web-video.mp4',
      },
    );

    expect(item.videoId, '');
    expect(item.videoUrl, 'https://example.com/old-web-video.mp4');
  });
}

RoutineExerciseItem _item({
  required String id,
  required String title,
  String categoryId = 'coolDown',
  String videoUrl = '',
}) {
  return RoutineExerciseItem(
    id: id,
    title: title,
    description: '',
    durationSeconds: 30,
    videoId: '',
    videoUrl: videoUrl,
    categoryId: categoryId,
  );
}

RoutineExerciseItem _handstandItem({
  required String id,
  required String title,
}) {
  return RoutineExerciseItem.fromMap(
    id: id,
    categoryId: 'freeHandstand',
    data: {
      'title_en': title,
      'description_en': '',
      'durationSeconds': 30,
      'VideoPortraitScreen': 'old-youtube-id',
      'videoShortUrl': 'https://example.com/old-web-video.mp4',
    },
  );
}
