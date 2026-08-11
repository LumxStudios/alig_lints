void constantIndex(List<int> items) {
  for (var index = 0; index < items.length; index++) {
    // The loop advances but the read does not: every pass sees the same element.
    // expect_lint: avoid-accessing-collections-by-constant-index
    print(items[0]);
  }
}

void constantIndexInForEach(List<int> items, List<int> others) {
  for (final item in items) {
    // expect_lint: avoid-accessing-collections-by-constant-index
    print(others[1] + item);
  }
}

void constantIndexInWhile(List<int> items) {
  var index = 0;
  while (index < items.length) {
    // expect_lint: avoid-accessing-collections-by-constant-index
    print(items[2]);
    index++;
  }
}

// The index varies with the loop.
void movingIndex(List<int> items) {
  for (var index = 0; index < items.length; index++) {
    print(items[index]);
  }
}

// A constant index outside a loop reads once, which is ordinary.
void outsideLoop(List<int> items) {
  print(items[0]);
}

// A map keyed by a constant is a lookup, not an index into a sequence.
void mapLookup(Map<String, int> byName, List<int> items) {
  for (final item in items) {
    print(byName['total'] ?? item);
  }
}
