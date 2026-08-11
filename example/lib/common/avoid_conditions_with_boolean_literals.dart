bool check() => true;

void main(List<String> args) {
  final flag = args.isEmpty;

  // The literal does not affect the result.
  // expect_lint: avoid-conditions-with-boolean-literals
  if (flag && true) print('and true');

  // expect_lint: avoid-conditions-with-boolean-literals
  if (flag || false) print('or false');

  // expect_lint: avoid-conditions-with-boolean-literals
  if (true && flag) print('true and');

  // expect_lint: avoid-conditions-with-boolean-literals
  if (false || flag) print('false or');

  // The result is always the same.
  // expect_lint: avoid-conditions-with-boolean-literals
  if (flag && false) print('never');

  // expect_lint: avoid-conditions-with-boolean-literals
  if (flag || true) print('always');

  // expect_lint: avoid-conditions-with-boolean-literals
  if (false && flag) print('never either');

  // expect_lint: avoid-conditions-with-boolean-literals
  if (true || flag) print('always either');

  // Reported, but not auto-fixed: collapsing would drop the call.
  // expect_lint: avoid-conditions-with-boolean-literals
  if (check() && false) print('call is evaluated');

  // Comparisons against literals belong to Dart's no_literal_bool_comparisons.
  if (flag == true) print('compared');

  // No literal involved.
  if (flag && check()) print('real condition');
}
