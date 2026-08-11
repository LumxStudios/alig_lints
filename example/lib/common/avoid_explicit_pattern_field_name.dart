class Point {
  Point(this.x, this.y);

  final int x;
  final int y;
}

String describeObject(Object value) {
  switch (value) {
    case Point(
      // expect_lint: avoid-explicit-pattern-field-name
      x: var x,
      // expect_lint: avoid-explicit-pattern-field-name
      y: var y,
    ):
      return '$x,$y';
    default:
      return 'other';
  }
}

String describeRenamed(Object value) {
  switch (value) {
    // A different variable name needs the explicit field name.
    case Point(x: var horizontal, y: var vertical):
      return '$horizontal,$vertical';
    default:
      return 'other';
  }
}

String describeShorthand(Object value) {
  switch (value) {
    case Point(:var x, :var y):
      return '$x,$y';
    default:
      return 'other';
  }
}

String describeRecord((int, {String label}) record) {
  final (
    first,
    // expect_lint: avoid-explicit-pattern-field-name
    label: label,
  ) = record;

  return '$first $label';
}
