bool check() => true;

// Both findings hold here and suggest different repairs: drop the redundant if,
// or make the branches return different things.
// expect_lint: function-always-returns-same-value
int classify(int value) {
  // expect_lint: avoid-unnecessary-if
  if (value > 0) {
    return 0;
  }

  return 0;
}

void earlyExit(int value) {
  // expect_lint: avoid-unnecessary-if
  if (value < 0) {
    return;
  }

  // Also a real finding: a trailing bare return in a void function.
  // expect_lint: avoid-unnecessary-return
  return;
}

// expect_lint: function-always-returns-same-value
int sideEffectCondition(int value) {
  // Reported, but not auto-fixed: dropping the if would drop the call.
  // expect_lint: avoid-unnecessary-if
  if (check()) {
    return 1;
  }

  return 1;
}

int keepsIf(int value) {
  if (value > 0) {
    return 1;
  }

  return 0;
}

// expect_lint: function-always-returns-same-value
int extraWork(int value) {
  // The then branch does more than return, so the if is not redundant.
  if (value > 0) {
    print('positive');

    return 0;
  }

  return 0;
}
