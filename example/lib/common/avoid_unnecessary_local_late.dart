int compute() => 1;

void unconditional() {
  // expect_lint: avoid-unnecessary-local-late
  late final int value;
  value = compute();

  print(value);
}

void bothBranches(bool flag) {
  // expect_lint: avoid-unnecessary-local-late
  late final int value;
  if (flag) {
    value = 1;
  } else {
    value = 2;
  }

  print(value);
}

void onlyOneBranch(bool flag) {
  // Assigned on one path only, so late carries the deferral.
  late final int value;
  if (flag) {
    value = 1;
  }

  print(flag ? value : 0);
}

void lazyInitializer() {
  // The initializer is deferred until first use, which is what late is for.
  late final value = compute();

  print(value);
}

void assignedLater(bool flag) {
  // Something happens before the assignment, so this is a real deferral.
  late final int value;
  print(flag);
  value = compute();

  print(value);
}
