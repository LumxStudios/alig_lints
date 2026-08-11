String classifyStatement(int value) {
  // expect_lint: avoid-constant-switches
  switch (1) {
    case 1:
      return 'one';
    default:
      return 'other';
  }
}

String classifyExpression() =>
    // expect_lint: avoid-constant-switches
    switch (2) {
      1 => 'one',
      _ => 'other',
    };

String arithmetic() {
  // expect_lint: avoid-constant-switches
  switch (1 + 1) {
    case 2:
      return 'two';
    default:
      return 'other';
  }
}

// A real switch.
String real(int value) {
  switch (value) {
    case 1:
      return 'one';
    default:
      return 'other';
  }
}
