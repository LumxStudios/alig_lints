int compute() => 1;

void accessors(int value) {
  // expect_lint: avoid-unnecessary-collections
  print([value].first);

  // expect_lint: avoid-unnecessary-collections
  print([value].last);

  // expect_lint: avoid-unnecessary-collections
  print([value].single);

  // expect_lint: avoid-unnecessary-collections
  print({value}.single);

  // expect_lint: avoid-unnecessary-collections
  print([compute()].first);
}

void spreads(int value, List<int> others) {
  // expect_lint: avoid-unnecessary-collections
  final combined = <int>[...[value], ...others];

  // expect_lint: avoid-unnecessary-collections
  final unique = <int>{...{value}, ...others};

  print([combined, unique]);
}

// More than one element, so the accessor is doing work.
void severalElements(int first, int second) {
  print([first, second].first);
  print(<int>[first, second].last);
}

// A real collection with a real accessor.
void realCollection(List<int> items) {
  print(items.first);
}

// Spreading something that is not a single-element literal.
void realSpread(List<int> items, int value) {
  print(<int>[...items, value]);
}

// The literal is the value, not a step towards one.
List<int> singleton(int value) => [value];
