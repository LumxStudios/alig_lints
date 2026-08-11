class Box {
  final items = <int>[];

  void copyFrom(Box other) {}

  int compareTo(Box other) => 0;

  void selfInside() {
    // expect_lint: avoid-passing-self-as-argument
    items.addAll(items);
  }
}

Box make() => Box();

void main() {
  final box = Box();
  final other = Box();
  final numbers = <int>[1, 2];

  // expect_lint: avoid-passing-self-as-argument
  box.copyFrom(box);

  // expect_lint: avoid-passing-self-as-argument
  numbers.addAll(numbers);

  // expect_lint: avoid-passing-self-as-argument
  print(box.compareTo(box));

  box.copyFrom(other);
  numbers.addAll([3]);
  print(box.compareTo(other));

  // Two separate calls, so not the same object.
  make().copyFrom(make());

  // A member of the receiver, not the receiver itself.
  box.items.addAll(other.items);
}
