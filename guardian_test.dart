
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:guardian_ai_app/main.dart';

void main() {
  group('GuardianHomePage Widget Tests', () {
    testWidgets('Button toggles color and text on press', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Verify initial state
      expect(find.text('Activate Safe Zone'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      ElevatedButton button = tester.widget(find.byType(ElevatedButton));
      expect(button.style?.backgroundColor?.resolve({MaterialState.none}), Colors.red);

      // Tap the button and trigger a frame
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle(); // Wait for animations and rebuilds

      // Verify state after first tap (activation)
      expect(find.text('Deactivate Safe Zone'), findsOneWidget);
      button = tester.widget(find.byType(ElevatedButton));
      expect(button.style?.backgroundColor?.resolve({MaterialState.none}), Colors.green);

      // Tap the button again and trigger a frame
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle(); // Wait for animations and rebuilds

      // Verify state after second tap (deactivation)
      expect(find.text('Activate Safe Zone'), findsOneWidget);
      button = tester.widget(find.byType(ElevatedButton));
      expect(button.style?.backgroundColor?.resolve({MaterialState.none}), Colors.red);
    });

    testWidgets('Phone number input field is present', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Emergency Phone Number'), findsOneWidget);
    });
  });
}


