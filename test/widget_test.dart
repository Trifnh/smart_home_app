import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_home_app/main.dart';

void main() {
  testWidgets('Init error placeholder renders guidance', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp(initError: 'Test: Firebase không khởi tạo'));
    await tester.pump();

    expect(find.textContaining('Firebase'), findsWidgets);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });
}
