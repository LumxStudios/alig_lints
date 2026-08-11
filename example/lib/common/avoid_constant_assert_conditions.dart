class Range {
  Range(this.start, this.end) {
    // expect_lint: avoid-constant-assert-conditions
    assert(true);

    // expect_lint: avoid-constant-assert-conditions
    assert(1 < 2, 'always passes');

    // expect_lint: avoid-constant-assert-conditions
    assert(2 < 1, 'always fails');

    // A real check.
    assert(start <= end, 'start must not exceed end');
  }

  final int start;
  final int end;
}

String describe(int value) {
  switch (value) {
    case 1:
      return 'one';
    default:
      // A bare `assert(false)` is the recognised way to mark a branch as
      // unreachable, so it is left alone.
      assert(false, 'unexpected value $value');

      return 'unknown';
  }
}
