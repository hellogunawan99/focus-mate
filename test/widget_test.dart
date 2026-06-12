// Smoke tests for Focus Mate.
import 'package:flutter_test/flutter_test.dart';

import 'package:focus_mate/core/math_problem.dart';

void main() {
  test('math generator produces non-trivial problems', () {
    final gen = MathProblemGenerator(seed: 42);
    for (var i = 0; i < 50; i++) {
      final p = gen.generate(tier: 3);
      expect(p.answer, isA<int>());
      expect(p.prompt.isNotEmpty, true);
      if (p.op == Operator.add || p.op == Operator.sub) {
        expect(p.left >= 10 && p.right >= 10, true);
      }
    }
  });

  test('mixed operators appear over many rolls', () {
    final gen = MathProblemGenerator(seed: 99);
    final seen = <Operator>{};
    for (var i = 0; i < 200; i++) {
      seen.add(gen.generate(tier: 3).op);
    }
    // Statistically all 4 ops should appear at least once in 200 rolls.
    expect(seen.contains(Operator.add), true);
    expect(seen.contains(Operator.sub), true);
    expect(seen.contains(Operator.mul), true);
    expect(seen.contains(Operator.div), true);
  });
}
