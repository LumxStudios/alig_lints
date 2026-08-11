class Builder {
  int width = 0;
  int height = 0;

  void grow(int by) {}
}

void main() {
  Builder()
    ..grow(1)
    // expect_lint: avoid-duplicate-cascades
    ..grow(1);

  Builder()
    ..width = 1
    ..height = 2
    // expect_lint: avoid-duplicate-cascades
    ..width = 1;

  // Different arguments, so not duplicates.
  Builder()
    ..grow(1)
    ..grow(2);

  // Different values assigned to the same field: a dead write, but not a
  // duplicate section. Deliberately not reported — see doc/LIMITATIONS.md.
  Builder()
    ..width = 1
    ..width = 3;

  // Distinct targets.
  Builder()
    ..width = 1
    ..height = 2;

  // Accumulator methods repeat meaningfully by design.
  <int>[]
    ..add(1)
    ..add(1);
}
