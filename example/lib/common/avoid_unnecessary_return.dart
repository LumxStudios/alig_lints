void trailing(int value) {
  print(value);
  // expect_lint: avoid-unnecessary-return
  return;
}

void onlyStatement() {
  // expect_lint: avoid-unnecessary-return
  return;
}

// expect_lint: avoid-unnecessary-futures
Future<void> asyncTrailing() async {
  print('work');
  // expect_lint: avoid-unnecessary-return
  return;
}

Stream<int> generator() async* {
  yield 1;
  // expect_lint: avoid-unnecessary-return
  return;
}

void earlyExit(int value) {
  // A guard clause is doing real work.
  if (value < 0) {
    return;
  }

  print(value);
}

int withValue(int value) {
  return value * 2;
}

void closures() {
  final callback = () {
    print('inside');
    // expect_lint: avoid-unnecessary-return
    return;
  };

  callback();
}
