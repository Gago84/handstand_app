import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:handstand_app/main.dart';
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

  testWidgets('female users receive one-rep initial requirements', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PrerequisiteScreen()));

    expect(find.text('What is your gender?'), findsOneWidget);
    expect(find.textContaining('regular pull up'), findsNothing);

    await tester.tap(find.text('Female'));
    await tester.pump();

    expect(find.text('Can you do 1 rep of regular pull up?'), findsOneWidget);
    expect(find.text('Can you do 1 rep of regular push up?'), findsOneWidget);
  });

  testWidgets('male users receive three-rep initial requirements', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PrerequisiteScreen()));

    await tester.tap(find.text('Male'));
    await tester.pump();

    expect(find.text('Can you do 3 reps of regular pull up?'), findsOneWidget);
    expect(find.text('Can you do 3 reps of regular push up?'), findsOneWidget);
  });

  testWidgets('debug prerequisite completion bypasses the premium gate', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: PrerequisiteScreen()));

    await tester.tap(find.text('Male'));
    await tester.pump();
    await tester.tap(find.text('Yes').first);
    await tester.pump();
    await tester.tap(find.text('Yes').last);
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Weekly Routine'), findsOneWidget);
    expect(find.text('Premium'), findsNothing);
  });
}
