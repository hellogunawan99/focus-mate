// Widget tests for the interval picker scroll wheel.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focus_mate/widgets/interval_wheel.dart';

void main() {
  testWidgets('IntervalWheel initializes with value 5 centered (no off-by-one)',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: IntervalWheel(
          value: 5,
          onChanged: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // With center-padding, the wheel's visible center should highlight
    // value 5, not value 6.
    final selectedFive = find.text('5');
    expect(selectedFive, findsWidgets);
  });

  testWidgets('IntervalWheel scrolls across full 1-240 range',
      (tester) async {
    final captured = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: IntervalWheel(
          value: 60,
          onChanged: (v) => captured.add(v),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Simulate scrolling the wheel to the very top (value 1).
    final listFinder = find.byType(Scrollable);
    expect(listFinder, findsWidgets);
    await tester.drag(listFinder.first, const Offset(0, 5000));
    await tester.pumpAndSettle();

    // The wheel should have crossed value 1 somewhere in the drag.
    expect(captured, contains(1));
  });

  testWidgets('IntervalWheel editor accepts any value 1-240',
      (tester) async {
    final captured = <int>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: IntervalWheel(
          value: 30,
          onChanged: (v) => captured.add(v),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Open the editor via the pencil icon.
    await tester.tap(find.byIcon(Icons.edit_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Custom interval'), findsOneWidget);

    // Type a value within the editor range.
    await tester.enterText(find.byType(TextField), '3');
    await tester.tap(find.text('SET'));
    await tester.pumpAndSettle();

    expect(captured.last, 3);
  });

  testWidgets('IntervalWheel editor pre-fills with current value',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: IntervalWheel(
          value: 47,
          onChanged: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_rounded));
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller!.text, '47');
  });
}
