typedef IntCallback = int Function(int);

class Multiplier {
  int call(int value) => value * 2;
}

void main() {
  final IntCallback twice = (value) => value * 2;
  final multiplier = Multiplier();
  final IntCallback? maybe = null;

  print(twice.call(2));
  print(multiplier.call(3));
  print(twice(2));
  print(maybe?.call(4));
  multiplier..call(5);
}
