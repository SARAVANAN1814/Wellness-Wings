import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wellness_wings/main.dart';

void main() {
  testWidgets('Wellness Wings app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WellnessWingsApp());

    // Verify that the welcome text is present
    expect(find.text('Welcome to Wellness Wings'), findsOneWidget);

    // Verify that the description text is present
    expect(
      find.text('Connecting elderly and physically challenged individuals with caring volunteers'),
      findsOneWidget,
    );

    // Verify that we have two buttons
    expect(find.byType(ElevatedButton), findsNWidgets(2));

    // Verify specific button texts
    expect(find.text('Elderly Login'), findsOneWidget);
    expect(find.text('Volunteer Login'), findsOneWidget);

    // Test navigation to elderly login page
    await tester.tap(find.text('Elderly Login'));
    await tester.pumpAndSettle();
    expect(find.text('Elderly Login'), findsOneWidget);

    // Navigate back
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Test navigation to volunteer login page
    await tester.tap(find.text('Volunteer Login'));
    await tester.pumpAndSettle();
    expect(find.text('Volunteer Login'), findsOneWidget);
  });

  testWidgets('Test elderly login form validation', (WidgetTester tester) async {
    await tester.pumpWidget(const WellnessWingsApp());

    // Navigate to elderly login
    await tester.tap(find.text('Elderly Login'));
    await tester.pumpAndSettle();

    // Try to login without entering any data
    await tester.tap(find.text('Login'));
    await tester.pump();

    // Verify validation messages
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });

  testWidgets('Test volunteer login form validation', (WidgetTester tester) async {
    await tester.pumpWidget(const WellnessWingsApp());

    // Navigate to volunteer login
    await tester.tap(find.text('Volunteer Login'));
    await tester.pumpAndSettle();

    // Try to login without entering any data
    await tester.tap(find.text('Login'));
    await tester.pump();

    // Verify validation messages
    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });
}
