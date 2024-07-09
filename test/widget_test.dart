import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:nba_salary_app/main.dart';

void main() {
  testWidgets('Test Widget', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp()); // Ensure 'MyApp' is the correct class and use 'const'
    // Add your test code here
  });
}
