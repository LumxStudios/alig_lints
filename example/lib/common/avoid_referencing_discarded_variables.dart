void locals() {
  final __ = compute();
  // expect_lint: avoid-referencing-discarded-variables
  print(__);
}

void parameters(int first, int __) {
  // expect_lint: avoid-referencing-discarded-variables
  print(first + __);
}

void patterns(List<int> values) {
  final [first, __] = values;
  // expect_lint: avoid-referencing-discarded-variables
  print(first + __);
}

void discarded() {
  final _ = compute();
  final named = compute();
  print(named);
}

int compute() => 1;
