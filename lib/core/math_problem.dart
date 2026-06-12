import 'dart:math';

/// Math operator types.
enum Operator { add, sub, mul, div }

extension OperatorSymbol on Operator {
  String get symbol => switch (this) {
        Operator.add => '+',
        Operator.sub => '−',
        Operator.mul => '×',
        Operator.div => '÷',
      };
}

/// A single math problem with operands, operator, and correct answer.
class MathProblem {
  final int left;
  final int right;
  final Operator op;
  final int answer;

  const MathProblem({
    required this.left,
    required this.right,
    required this.op,
    required this.answer,
  });

  String get prompt => '$left ${op.symbol} $right';

  /// Difficulty tier. We target tier 2-3 by default — non-trivial but
  /// solvable in <15 seconds for a working adult.
  int get difficulty {
    if (op == Operator.mul) {
      if (left <= 9 && right <= 9) return 1; // single digit times table
      if (left <= 12 && right <= 12) return 2; // 11-12 tables
      if (left <= 20 || right <= 20) return 3; // 2-digit
      return 4;
    }
    if (op == Operator.div) return 2 + (left ~/ 10).clamp(0, 3);
    final maxNum = max(left.abs(), right.abs());
    if (maxNum < 30) return 1;
    if (maxNum < 100) return 2;
    if (maxNum < 300) return 3;
    return 4;
  }
}

/// Generates moderately-difficulty arithmetic problems mixing +/−/×/÷ on
/// 2-3 digit numbers. Avoids trivial 1+1 or 9999×9999 cases.
class MathProblemGenerator {
  final Random _rng;

  MathProblemGenerator({int? seed}) : _rng = Random(seed);

  /// Returns a fresh problem. [tier] ∈ [1,5], default 3 (moderate).
  MathProblem generate({int tier = 3}) {
    // We rotate through operators to ensure variety; not purely random so
    // the user gets the full mix.
    final op = _pickOperator(tier);
    switch (op) {
      case Operator.add:
        return _addition(tier);
      case Operator.sub:
        return _subtraction(tier);
      case Operator.mul:
        return _multiplication(tier);
      case Operator.div:
        return _division(tier);
    }
  }

  Operator _pickOperator(int tier) {
    // All four ops roughly equally likely, with a tiny bias toward tier's
    // preferred operator (tier 3 → multiplication slightly favored).
    final pool = <Operator>[
      Operator.add,
      Operator.sub,
      Operator.mul,
      Operator.div,
    ];
    return pool[_rng.nextInt(pool.length)];
  }

  MathProblem _addition(int tier) {
    final upper = _upperBound(tier);
    final a = 10 + _rng.nextInt(upper - 9);
    final b = 10 + _rng.nextInt(upper - 9);
    return MathProblem(left: a, right: b, op: Operator.add, answer: a + b);
  }

  MathProblem _subtraction(int tier) {
    final upper = _upperBound(tier);
    final a = 30 + _rng.nextInt(upper - 29);
    final b = 10 + _rng.nextInt(a - 9); // ensure non-negative result
    return MathProblem(left: a, right: b, op: Operator.sub, answer: a - b);
  }

  MathProblem _multiplication(int tier) {
    // Tier 1-2 → single digit; tier 3-4 → 2-digit; tier 5 → 3-digit.
    switch (tier) {
      case 1:
        final a = 2 + _rng.nextInt(8);
        final b = 2 + _rng.nextInt(8);
        return MathProblem(
            left: a, right: b, op: Operator.mul, answer: a * b);
      case 2:
        final a = 2 + _rng.nextInt(11);
        final b = 2 + _rng.nextInt(11);
        return MathProblem(
            left: a, right: b, op: Operator.mul, answer: a * b);
      case 3:
        final a = 11 + _rng.nextInt(20); // 11..30
        final b = 2 + _rng.nextInt(11); // 2..12
        return MathProblem(
            left: a, right: b, op: Operator.mul, answer: a * b);
      case 4:
        final a = 20 + _rng.nextInt(80); // 20..99
        final b = 11 + _rng.nextInt(20); // 11..30
        return MathProblem(
            left: a, right: b, op: Operator.mul, answer: a * b);
      default:
        final a = 100 + _rng.nextInt(400);
        final b = 20 + _rng.nextInt(80);
        return MathProblem(
            left: a, right: b, op: Operator.mul, answer: a * b);
    }
  }

  MathProblem _division(int tier) {
    // Always generate a whole-number result by choosing result×divisor.
    switch (tier) {
      case 1:
        final divisor = 2 + _rng.nextInt(8);
        final result = 2 + _rng.nextInt(11);
        final dividend = divisor * result;
        return MathProblem(
            left: dividend,
            right: divisor,
            op: Operator.div,
            answer: result);
      case 2:
        final divisor = 2 + _rng.nextInt(11);
        final result = 2 + _rng.nextInt(20);
        return MathProblem(
            left: divisor * result,
            right: divisor,
            op: Operator.div,
            answer: result);
      case 3:
        final divisor = 6 + _rng.nextInt(15); // 6..20
        final result = 10 + _rng.nextInt(40); // 10..49
        return MathProblem(
            left: divisor * result,
            right: divisor,
            op: Operator.div,
            answer: result);
      case 4:
        final divisor = 11 + _rng.nextInt(30); // 11..40
        final result = 20 + _rng.nextInt(80);
        return MathProblem(
            left: divisor * result,
            right: divisor,
            op: Operator.div,
            answer: result);
      default:
        final divisor = 20 + _rng.nextInt(60);
        final result = 50 + _rng.nextInt(150);
        return MathProblem(
            left: divisor * result,
            right: divisor,
            op: Operator.div,
            answer: result);
    }
  }

  int _upperBound(int tier) => switch (tier) {
        1 => 30,
        2 => 99,
        3 => 300,
        4 => 999,
        _ => 9999,
      };
}
