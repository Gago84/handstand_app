import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:handstand_app/main.dart';
import 'package:handstand_app/screens/home_screen.dart';
import 'package:handstand_app/screens/prerequisite_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('new users start on the welcome screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const HandstandApp(enableUpgradeCheck: false));

    expect(find.text('Handstand Journey'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('returning users skip the survey after welcome', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'initial_requirements_passed': true,
      'skip_welcome_screen': false,
      'routine_level_v1': 'beginner',
      'basic_strength_passed_v1': true,
    });
    await tester.pumpWidget(const HandstandApp(enableUpgradeCheck: false));

    expect(find.text('Handstand Journey'), findsOneWidget);
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Weekly Routine'), findsOneWidget);
    expect(find.text('Let’s Personalize Your Plan'), findsNothing);
  });

  testWidgets('onboarding shows gender and two strength questions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PrerequisiteScreen()));

    expect(find.textContaining('What is your gender?'), findsOneWidget);
    expect(
      find.textContaining('How many pull-ups can you do?'),
      findsOneWidget,
    );
    expect(
      find.textContaining('How many push-ups can you do?'),
      findsOneWidget,
    );
    expect(find.text('0 reps'), findsNWidgets(2));
    expect(find.text('1–3 reps'), findsNWidgets(2));
    expect(find.text('4–6 reps'), findsNWidgets(2));
    expect(find.text('7–10 reps'), findsNWidgets(2));
  });

  testWidgets('answers choose the lower ability level and show loading', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PrerequisiteScreen()));

    await tester.tap(find.text('Female'));
    await _tapVisible(tester, find.text('7–10 reps').first);
    await _tapVisible(tester, find.text('4–6 reps').last);
    await _tapVisible(tester, find.text('Create My Plan'));
    await tester.pump();

    expect(find.text('Designing your workout plan…'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('user_gender_v1'), 'female');
    expect(prefs.getString('routine_level_v1'), 'intermediate');
    expect(prefs.getBool('initial_requirements_passed'), isTrue);
    expect(prefs.getBool('basic_strength_passed_v1'), isTrue);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('Weekly Routine'), findsOneWidget);
  });

  testWidgets('zero reps keeps Basic Strength open for practice', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'user_gender_v1': 'male',
      'initial_pull_up_range_v1': 'zero',
      'initial_push_up_range_v1': 'zero',
      'basic_strength_passed_v1': false,
    });
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Basic Strength'), findsOneWidget);
    expect(
      find.text('Goal: 3 reps regular pull-up + 3 reps regular push-up'),
      findsOneWidget,
    );
    expect(find.text('Resistance band for first pull-up'), findsOneWidget);
    expect(find.text('Negative pull-up'), findsOneWidget);
    expect(find.text('Incline push-up'), findsOneWidget);
  });

  testWidgets('only zero pull-ups shows pull-up goal and videos', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'user_gender_v1': 'male',
      'initial_pull_up_range_v1': 'zero',
      'initial_push_up_range_v1': 'oneToThree',
      'basic_strength_passed_v1': false,
    });
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Goal: 3 reps regular pull-up'), findsOneWidget);
    expect(find.text('Resistance band for first pull-up'), findsOneWidget);
    expect(find.text('Negative pull-up'), findsOneWidget);
    expect(find.text('Incline push-up'), findsNothing);
  });

  testWidgets('only zero push-ups shows push-up goal and video', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'user_gender_v1': 'female',
      'initial_pull_up_range_v1': 'oneToThree',
      'initial_push_up_range_v1': 'zero',
      'basic_strength_passed_v1': false,
    });
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Goal: 1 rep regular push-up'), findsOneWidget);
    expect(find.text('Incline push-up'), findsOneWidget);
    expect(find.text('Resistance band for first pull-up'), findsNothing);
    expect(find.text('Negative pull-up'), findsNothing);
  });

  testWidgets('completed Basic Strength is displayed as a compact check', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'user_gender_v1': 'female',
      'basic_strength_passed_v1': true,
    });
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Basic Strength completed'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.textContaining('Goal:'), findsNothing);
  });
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}
