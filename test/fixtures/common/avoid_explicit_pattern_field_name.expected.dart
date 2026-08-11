class Point {
  Point(this.x, this.y);

  final int x;
  final int y;
}

String describeObject(Object value) {
  switch (value) {
    case Point(:var x, :var y):
      return '$x,$y';
    default:
      return 'other';
  }
}

String describeRenamed(Object value) {
  switch (value) {
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
