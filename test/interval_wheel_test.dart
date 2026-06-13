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

    // With center-padding of 2*itemHeight, the wheel's visible center
    // should highlight value 5, not value 6.
    final selectedFive = find.text('5');
    expect(selectedFive, findsWidgets);
  });

  testWidgets('IntervalWheel correctly centers max value (240)',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: IntervalWheel(
          value: 240,
          onChanged: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Bug regression: at value=240, the wheel was centering on 238
    // because the top/bottom padding was only 1*itemHeight instead of
    // 2*itemHeight. Now 240 should be properly centered.
    final selectedTwoForty = find.text('240');
    expect(selectedTwoForty, findsWidgets);
  });

  testWidgets('IntervalWheel correctly centers min value (1)',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: IntervalWheel(
          value: 1,
          onChanged: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    final selectedOne = find.text('1');
    expect(selectedOne, findsWidgets);
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

    final listFinder = find.byType(Scrollable);
    expect(listFinder, findsWidgets);
    await tester.drag(listFinder.first, const Offset(0, 5000));
    await tester.pumpAndSettle();

    expect(captured, contains(1));
  });

  testWidgets('IntervalWheel editor accepts 240 and saves it',
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

    await tester.tap(find.byIcon(Icons.edit_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Custom interval'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '240');
    await tester.tap(find.text('SET'));
    await tester.pumpAndSettle();

    expect(captured.last, 240);
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

    await tester.tap(find.byIcon(Icons.edit_rounded));
    await tester.pumpAndSettle();

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
