void main(List<String> args) {
  final count = args.length;

  // expect_lint: avoid-constant-conditions
  if (1 < 2) print('always');

  // expect_lint: avoid-constant-conditions
  if (3 == 4) print('never');

  // expect_lint: avoid-constant-conditions
  if ('a' != 'b') print('always');

  // expect_lint: avoid-constant-conditions
  final flag = 10 >= 20;

  // Equal sides belong to avoid-self-compare.
  // expect_lint: avoid-self-compare
  if (1 == 1) print('self');

  // Boolean literals in a logical chain belong to
  // avoid-conditions-with-boolean-literals.
  // expect_lint: avoid-conditions-with-boolean-literals
  if (true && count > 0) print('literal chain');

  // Constant conditions inside asserts belong to
  // avoid-constant-assert-conditions.
  // expect_lint: avoid-constant-assert-conditions
  assert(2 < 3, 'always passes');

  // Real conditions.
  if (count > 0) print('real');
  if (count == args.length) print('also real');

  print(flag);
}
