class Box {
  int value = 0;

  void bump() {}
}

Box? find(bool present) => present ? Box() : null;

void main() {
  final fallback = Box();

  // expect_lint: avoid-cascade-after-if-null
  find(false) ?? fallback..bump();

  // Both readings written out explicitly.
  (find(false) ?? fallback)..bump();
  find(false) ?? (fallback..bump());

  // No if-null involved.
  fallback..bump();
}
