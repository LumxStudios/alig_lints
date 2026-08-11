String statement(int value, bool flag) {
  switch (value) {
    case 1:
      return 'one';
    case 2:
      return 'two';
    // expect_lint: avoid-duplicate-switch-case-conditions
    case 1:
      return 'uno';

    // Same pattern but a different guard, so genuinely a different case.
    case 3 when flag:
      return 'three when flag';
    case 3:
      return 'three';

    default:
      return 'other';
  }
}

String expression(int value) => switch (value) {
      1 => 'one',
      2 => 'two',
      // expect_lint: avoid-duplicate-switch-case-conditions
      1 => 'uno',
      _ => 'other',
    };
