String classifyStatement() {
  switch (1) {
    case 1:
      return 'one';
    default:
      return 'other';
  }
}

String classifyExpression() => switch (2) {
      1 => 'one',
      _ => 'other',
    };

String arithmetic() {
  switch (1 + 1) {
    case 2:
      return 'two';
    default:
      return 'other';
  }
}

String real(int value) {
  switch (value) {
    case 1:
      return 'one';
    default:
      return 'other';
  }
}
