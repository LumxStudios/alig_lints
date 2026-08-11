void accessors(List<int> items) {
  // expect_lint: avoid-unsafe-collection-methods
  print(items.first);

  // expect_lint: avoid-unsafe-collection-methods
  print(items.last);

  // expect_lint: avoid-unsafe-collection-methods
  print(items.single);
}

void searches(List<int> items) {
  // Throws when nothing matches.
  // expect_lint: avoid-unsafe-collection-methods
  print(items.firstWhere((value) => value > 0));

  // expect_lint: avoid-unsafe-collection-methods
  print(items.lastWhere((value) => value > 0));

  // expect_lint: avoid-unsafe-collection-methods
  print(items.singleWhere((value) => value > 0));

  // expect_lint: avoid-unsafe-collection-methods
  print(items.reduce((a, b) => a + b));

  // expect_lint: avoid-unsafe-collection-methods
  print(items.elementAt(2));
}

// An orElse makes the search total.
void guarded(List<int> items) {
  print(items.firstWhere((value) => value > 0, orElse: () => 0));
  print(items.lastWhere((value) => value > 0, orElse: () => 0));
}

// A non-empty literal cannot be empty.
void literals() {
  print([1, 2, 3].first);
  print(<int>{1, 2}.last);
}

// fold has a seed, so it works on an empty collection.
void total(List<int> items) {
  print(items.fold<int>(0, (sum, value) => sum + value));
}

// A map is not indexed this way.
void maps(Map<String, int> byName) {
  print(byName['a']);
}
