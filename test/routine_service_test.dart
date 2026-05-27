import 'package:flutter_test/flutter_test.dart';
import 'package:handstand_app/data/routine_service.dart';
import 'package:handstand_app/models/routine.dart';

void main() {
  test('buildSessionSteps completes all exercises in each set first', () {
    const day = RoutineDay(
      key: 'day5',
      title: 'Joints',
      label: '5',
      index: 4,
      items: [
        'Overhead rod',
        'Bridge',
        'DownDog',
        'Deep squat',
        'Lunge',
        'catcow',
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
    ]);
  });

  test('buildSessionSteps adds one-set warm ups before Sunday handstand', () {
    const day = RoutineDay(
      key: 'sunday',
      title: 'Handstand training',
      label: 'Sunday',
      index: 7,
      items: ['Warm up', 'Back to wall', 'Face to wall', 'Exit', 'Free'],
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
      'Warm up wrist 1',
      'Warm up shoulder 1',
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
    ]);
    expect(steps[0].durationSeconds, 60);
    expect(steps[0].totalSets, 1);
    expect(steps[0].restSeconds, 0);
    expect(steps[0].item.videoUrl, 'assets/video/HS-warmUp-wrist.mp4');
    expect(steps[1].durationSeconds, 60);
    expect(steps[1].totalSets, 1);
    expect(steps[1].restSeconds, 0);
    expect(steps[1].item.videoUrl, 'assets/video/HS-warmUp-Shoulder.mp4');
    expect(steps[2].restSeconds, 60);
    expect(steps[2].item.videoUrl, 'assets/video/HS-BackToWall.mp4');
  });

  test('Sunday routine rest is 60 seconds even if source still says 120', () {
    final day = RoutineDay.fromMap({
      'key': 'sunday',
      'title_en': 'Handstand training',
      'index': 7,
      'items': ['Back to wall'],
      'prescription': {'set': 3, 'rep': '30s', 'rest': '120s'},
    });

    expect(day.restSeconds, 60);
  });

  test('free handstand items prefer bundled app videos over old links', () {
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
    expect(item.videoUrl, 'assets/video/HS-FaceToWall.mp4');
  });
}

RoutineExerciseItem _item({required String id, required String title}) {
  return RoutineExerciseItem(
    id: id,
    title: title,
    description: '',
    durationSeconds: 30,
    videoId: '',
    videoUrl: '',
    categoryId: 'coolDown',
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
