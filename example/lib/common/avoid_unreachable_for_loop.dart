// This file demonstrates a different rule; its uses of first/last/single
// are incidental.
// ignore_for_file: avoid-unsafe-collection-methods

void emptyThen(List<int> items) {
  if (items.isEmpty) {
    // expect_lint: avoid-unreachable-for-loop
    for (final item in items) {
      print(item);
    }
  }
}

void lengthZero(List<int> items) {
  if (items.length == 0) {
    // expect_lint: avoid-unreachable-for-loop
    for (final item in items) {
      print(item);
    }
  }
}

void notEmptyElse(List<int> items) {
  if (items.isNotEmpty) {
    print(items.first);
  } else {
    // expect_lint: avoid-unreachable-for-loop
    for (final item in items) {
      print(item);
    }
  }
}

void negatedNotEmpty(List<int> items) {
  if (!items.isNotEmpty) {
    // expect_lint: avoid-unreachable-for-loop
    for (final item in items) {
      print(item);
    }
  }
}

// The branch fills the collection first, so the loop does run.
void fillsFirst(List<int> items) {
  if (items.isEmpty) {
    items.add(1);
    for (final item in items) {
      print(item);
    }
  }
}

// A different collection.
void differentCollection(List<int> items, List<int> others) {
  if (items.isEmpty) {
    for (final other in others) {
      print(other);
    }
  }
}

// The usual way round.
void reachable(List<int> items) {
  if (items.isNotEmpty) {
    for (final item in items) {
      print(item);
    }
  }
}
