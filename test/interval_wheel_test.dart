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

  testWidgets('IntervalWheel selection band is vertically centered with the selected value',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: IntervalWheel(
          value: 79,
          onChanged: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // The yellow selection band is a Container with the amber-tinted
    // background (alpha 0.10). Find it via its decoration color.
    final bandFinder = find.byWidgetPredicate((w) {
      if (w is! Container) return false;
      final deco = w.decoration;
      if (deco is! BoxDecoration) return false;
      final c = deco.color;
      return c != null && c.alpha < 50; // alpha 0.10 = ~25/255
    });
    expect(bandFinder, findsWidgets);
    final bandCenter = tester.getCenter(bandFinder.first).dy;

    // Find the selected '79' text widget (rendered with bold + 26px).
    final selectedText = find.text('79').first;
    final textCenter = tester.getCenter(selectedText).dy;

    // Band and selected text should be at the same y-position (within
    // 2 logical pixels to absorb sub-pixel rendering).
    expect(
      (bandCenter - textCenter).abs() < 2.0,
      isTrue,
      reason: 'Band center ($bandCenter) should align with selected '
          'text center ($textCenter)',
    );
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
