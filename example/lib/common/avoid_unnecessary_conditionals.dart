bool describe(int value, bool flag) {
  // expect_lint: avoid-unnecessary-conditionals
  final isPositive = value > 0 ? true : false;

  // expect_lint: avoid-unnecessary-conditionals
  final isNotPositive = value > 0 ? false : true;

  // The condition needs parentheses once negated.
  // expect_lint: avoid-unnecessary-conditionals
  final neither = flag && value > 0 ? false : true;

  // A plain identifier does not.
  // expect_lint: avoid-unnecessary-conditionals
  final negated = flag ? false : true;

  // Real conditionals stay.
  final label = value > 0 ? 'positive' : 'other';
  // One literal branch: prefer-simpler-boolean-expressions' shape, not this
  // rule's.
  // expect_lint: prefer-simpler-boolean-expressions
  final mixed = value > 0 ? true : flag;

  print([isNotPositive, neither, negated, label, mixed]);

  return isPositive;
}
