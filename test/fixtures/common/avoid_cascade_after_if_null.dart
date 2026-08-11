class Box {
  int value = 0;

  void bump() {}
}

Box? find() => null;

void main() {
  final fallback = Box();

  find() ?? fallback..bump();
  (find() ?? fallback)..bump();
  find() ?? (fallback..bump());
  fallback..bump();
}
