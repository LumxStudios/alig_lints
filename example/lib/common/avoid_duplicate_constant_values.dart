class Timeouts {
  static const short = 5;
  static const medium = 10;

  // expect_lint: avoid-duplicate-constant-values
  static const quick = 5;
}

class Labels {
  static const ok = 'ok';

  // expect_lint: avoid-duplicate-constant-values
  static const accepted = 'ok';

  // Different type with an equal-looking literal.
  static const okCode = 0;
}

enum Priority {
  low(1),
  high(2),

  // expect_lint: avoid-duplicate-constant-values
  urgent(2);

  const Priority(this.weight);

  final int weight;
}

class Distinct {
  static const a = 1;
  static const b = 2;
  static const c = 'a';
  static const d = true;
  static const e = false;
}

class NotConstants {
  // Not static const, so repeated values are ordinary state.
  final int first = 1;
  final int second = 1;
}

class ComputedValues {
  // Not literals: constant evaluation is out of scope.
  static const a = 1 + 1;
  static const b = 2;
}
