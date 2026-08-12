void locals() {
  final __ = compute();
  print(__);
}

void parameters(int first, int __) {
  print(first + __);
}

void patterns(List<int> values) {
  final [first, __] = values;
  print(first + __);
}

void discarded() {
  final _ = compute();
  final named = compute();
  print(named);
}

int compute() => 1;
