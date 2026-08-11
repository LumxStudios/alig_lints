bool hasMore() => false;

void wrongVariable(int limit) {
  var other = 0;

  // Nothing in the condition ever changes, so this loop cannot end.
  // expect_lint: prefer-correct-for-loop-increment
  for (var index = 0; index < limit; other++) {
    print(index);
  }
}

void wrongVariableDeclaredOutside(int limit) {
  var index = 0;
  var other = 0;

  // expect_lint: prefer-correct-for-loop-increment
  for (index = 0; index < limit; other++) {
    print(index);
  }
}

// The loop variable is the one being updated.
void correct(int limit) {
  for (var index = 0; index < limit; index++) {
    print(index);
  }
}

// Two counters, both updated.
void twoCounters(int limit) {
  for (var low = 0, high = limit; low < high; low++, high--) {
    print('$low $high');
  }
}

// The condition depends on state the updater does not touch, which is fine.
void externalCondition() {
  for (var index = 0; hasMore(); index++) {
    print(index);
  }
}

// No updater at all: the body advances the loop.
void bodyAdvances(int limit) {
  for (var index = 0; index < limit;) {
    index++;
  }
}

// A for-each has no updater clause.
void forEach(List<int> items) {
  for (final item in items) {
    print(item);
  }
}
