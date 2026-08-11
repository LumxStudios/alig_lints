bool check() => true;

int pick(bool flag, int a, int b) {
  // Both findings are true here and suggest different remedies: collapse the
  // branches, or drop the else that follows a returning branch.
  // expect_lint: no-equal-then-else
  if (flag) {
    return a;
  }
  // expect_lint: avoid-redundant-else
  else {
    return a;
  }
}

void run(bool flag) {
  // expect_lint: no-equal-then-else
  if (flag) {
    print('same');
  } else {
    print('same');
  }

  // Braces on one side only, still the same statement.
  // expect_lint: no-equal-then-else
  if (flag) {
    print('mixed');
  } else
    print('mixed');

  // The condition does work, so it is reported but not auto-fixed.
  // expect_lint: no-equal-then-else
  if (check()) {
    print('side effect');
  } else {
    print('side effect');
  }

  // Genuinely different branches.
  if (flag) {
    print('then');
  } else {
    print('else');
  }
}

int ternary(bool flag, int a, int b) {
  // expect_lint: no-equal-then-else
  final same = flag ? a : a;
  final different = flag ? a : b;

  return same + different;
}
