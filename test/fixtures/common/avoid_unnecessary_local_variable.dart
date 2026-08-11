int compute() => 1;

void indirect() {
  final temp = compute();
  final result = temp;

  print(result);
}

void usedInExpression() {
  final base = compute();
  final scaled = base * 2;

  print(scaled);
}

void usedTwice() {
  final base = compute();
  final copy = base;

  print([base, copy]);
}

void usedDirectly() {
  final value = compute();

  print(value);
}

void chained() {
  final first = compute();
  final second = first;
  final third = second;

  print(third);
}
