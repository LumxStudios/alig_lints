void nestedBlocks() {
  final value = 1;
  {
    // expect_lint: avoid-shadowing
    final value = 2;
    print(value);
  }
  print(value);
}

void closureParameter(List<int> items) {
  final item = 0;
  // expect_lint: avoid-shadowing
  items.forEach((item) => print(item));
  print(item);
}

void loopVariable(List<int> items) {
  final index = 0;
  // expect_lint: avoid-shadowing
  for (final index in items) {
    print(index);
  }
  print(index);
}

void distinctNames() {
  final outer = 1;
  {
    final inner = 2;
    print(inner);
  }
  print(outer);
}

class Holder {
  const Holder(this.value);

  final int value;

  // A parameter taking a field's name is how Dart is written.
  int scaled(int value) => this.value * value;
}
