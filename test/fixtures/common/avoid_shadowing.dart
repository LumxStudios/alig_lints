void nestedBlocks() {
  final value = 1;
  {
    final value = 2;
    print(value);
  }
  print(value);
}

void closureParameter(List<int> items) {
  final item = 0;
  items.forEach((item) => print(item));
  print(item);
}

void loopVariable(List<int> items) {
  final index = 0;
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
  Holder(this.value);

  final int value;

  // A parameter taking a field's name is how Dart is written.
  int scaled(int value) => this.value * value;
}
