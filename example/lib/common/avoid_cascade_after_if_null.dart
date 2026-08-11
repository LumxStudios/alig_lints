class Box {
  int value = 0;

  void bump() {}
}

Box? find() => null;

void main() {
  final fallback = Box();

  // expect_lint: avoid-cascade-after-if-null
  find() ?? fallback..bump();

  // Both readings written out explicitly.
  (find() ?? fallback)..bump();
  find() ?? (fallback..bump());

  // No if-null involved.
  fallback..bump();
}
