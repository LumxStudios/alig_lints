class Box {
  final items = <int>[];

  void copyFrom(Box other) {}

  int compareTo(Box other) => 0;

  void selfInside() {
    items.addAll(items);
  }
}

Box make() => Box();

void main() {
  final box = Box();
  final other = Box();
  final numbers = <int>[1, 2];

  box.copyFrom(box);
  numbers.addAll(numbers);
  print(box.compareTo(box));

  box.copyFrom(other);
  numbers.addAll([3]);
  make().copyFrom(make());
  box.items.addAll(other.items);
}
