class Range {
  Range(this.start, this.end) {
    assert(true);
    assert(1 < 2, 'always passes');
    assert(2 < 1, 'always fails');
    assert(start <= end, 'real check');
  }

  final int start;
  final int end;
}

String describe(int value) {
  if (value == 1) return 'one';

  assert(false, 'unexpected value $value');

  return 'unknown';
}
