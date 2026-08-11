int compute() => 1;

void indirect() {
  // expect_lint: avoid-unnecessary-local-variable
  final temp = compute();
  final result = temp;

  print(result);
}

void usedInExpression() {
  // Part of a larger expression, so the variable is carrying its own weight.
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
  // Both links are pointless intermediates.
  // expect_lint: avoid-unnecessary-local-variable
  final first = compute();
  // expect_lint: avoid-unnecessary-local-variable
  final second = first;
  final third = second;

  print(third);
}
