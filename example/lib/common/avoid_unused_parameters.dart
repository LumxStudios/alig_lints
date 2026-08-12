// expect_lint: avoid-unused-parameters
int counted(int value, int ignored) => value * 2;

int used(int value, int factor) => value * factor;

int discarded(int value, int _) => value * 2;

abstract class Base {
  int scaled(int value, int factor);
}

class Child extends Base {
  // The signature is inherited, so the unused one is not this method's choice.
  @override
  int scaled(int value, int factor) => value * 2;
}

class Holder {
  Holder(this.value, int unusedInConstructor);

  final int value;

  // expect_lint: avoid-unused-parameters
  int combine(int other, int unusedHere) => value + other;
}
