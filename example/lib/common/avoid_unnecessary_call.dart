typedef IntCallback = int Function(int);

class Multiplier {
  int call(int value) => value * 2;
}

void main() {
  final IntCallback twice = (value) => value * 2;
  final multiplier = Multiplier();
  final IntCallback? maybe = null;

  // expect_lint: avoid-unnecessary-call
  print(twice.call(2));

  // A class with a call method is callable directly too.
  // expect_lint: avoid-unnecessary-call
  print(multiplier.call(3));

  print(twice(2));
  print(multiplier(3));

  // A null-aware call has no shorthand, so it stays.
  print(maybe?.call(4));

  // A cascade section cannot drop the name either.
  multiplier..call(5);
}
