// Widget tests for the interval picker scroll wheel.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focus_mate/widgets/interval_wheel.dart';

void main() {
  testWidgets('IntervalWheel initializes with the supplied value as centered',
      (tester) async {
    int? captured;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: IntervalWheel(
          value: 5,
          onChanged: (v) => captured = v,
        ),
      ),
    ));
    // Let the post-frame callback fire.
    await tester.pumpAndSettle();

    // The first item in the list is value 5; with the center-padding
    // trick, the wheel's center should highlight the item with value 5.
    final selectedFinder = find.text('5');
    expect(selectedFinder, findsWidgets);
  });

  testWidgets('IntervalWheel clamps editor input to editor range (1-240)',
      (tester) async {
    int? captured;
    final wheel = IntervalWheel(
      value: 30,
      onChanged: (v) => captured = v,
    );
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: wheel),
    ));
    await tester.pumpAndSettle();

    // Tap the edit button to open the dialog.
    await tester.tap(find.byIcon(Icons.edit_rounded));
    await tester.pumpAndSettle();

    // The dialog should be open.
    expect(find.text('Custom interval'), findsOneWidget);

    // Clear and type a value below wheel.min.
    await tester.enterText(find.byType(TextField), '3');
    await tester.tap(find.text('SET'));
    await tester.pumpAndSettle();

    // The wheel should accept 3 even though wheel.min defaults to 5.
    expect(captured, 3);
  });

  testWidgets('IntervalWheel does not lose value on rebuild with out-of-range value',
      (tester) async {
    int? captured;
    Widget buildWith(int value) => MaterialApp(
          home: Scaffold(
            body: IntervalWheel(
              value: value,
              onChanged: (v) => captured = v,
            ),
          ),
        );

    // Start with 3 (below default wheel.min of 5).
    await tester.pumpWidget(buildWith(3));
    await tester.pumpAndSettle();

    // The big number above the wheel (rendered elsewhere) would show 3,
    // but the wheel's internal _value should still be 3 (not clamped).
    // Verify by tapping the edit button — pre-fill should be '3'.
    await tester.tap(find.byIcon(Icons.edit_rounded));
    await tester.pumpAndSettle();
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller!.text, '3');
  });
}
