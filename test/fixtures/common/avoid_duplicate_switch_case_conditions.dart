String statement(int value, bool flag) {
  switch (value) {
    case 1:
      return 'one';
    case 2:
      return 'two';
    case 1:
      return 'uno';
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
      1 => 'uno',
      _ => 'other',
    };
