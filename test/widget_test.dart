import 'package:flutter_test/flutter_test.dart';

import 'package:handstand_app/main.dart';

void main() {
  testWidgets('new users start on the welcome screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const HandstandApp());

    expect(find.text('Handstand Journey'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
