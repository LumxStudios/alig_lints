void accessors(List<int> items) {
  print(items.first);
  print(items.last);
  print(items.single);
}

void searches(List<int> items) {
  print(items.firstWhere((value) => value > 0));
  print(items.reduce((a, b) => a + b));
  print(items.elementAt(2));
}

void guarded(List<int> items) {
  print(items.firstWhere((value) => value > 0, orElse: () => 0));
}

void literals() {
  print([1, 2, 3].first);
}

void total(List<int> items) {
  print(items.fold<int>(0, (sum, value) => sum + value));
}
