void main(List<String> args) {
  final flag = args.isEmpty;
  final count = args.length;
  final Object value = count;
  final double ratio = count / 2;

  // expect_lint: avoid-unnecessary-negations
  if (!!flag) print('double negation');

  // expect_lint: avoid-unnecessary-negations
  if (!(count == 1)) print('not equal');

  // expect_lint: avoid-unnecessary-negations
  if (!(count != 1)) print('equal');

  // expect_lint: avoid-unnecessary-negations
  if (!(value is String)) print('not a string');

  // expect_lint: avoid-unnecessary-negations
  if (!(value is! String)) print('is a string');

  // Relational negation is not the same thing on doubles: with NaN, neither
  // `ratio < 1` nor `ratio >= 1` holds, so the two differ.
  if (!(ratio < 1)) print('not less');

  // A single negation is fine.
  if (!flag) print('plain');

  // De Morgan is a rewrite, not a simplification.
  if (!(flag && count > 0)) print('neither');
}
