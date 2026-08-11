class Plain {
  final int value = 1;
}

class Described {
  @override
  String toString() => 'Described';
}

class InheritsDescription extends Described {}

mixin Describing {
  @override
  String toString() => 'Describing';
}

class UsesMixin with Describing {}

abstract class Shape {
  double get area;
}

enum Color { red, green }

class Reporting extends Described {
  @override
  String toString() => 'Reporting via ${super.toString()}';
}

void log(
  Plain plain,
  Described described,
  InheritsDescription inherited,
  UsesMixin mixed,
  Shape shape,
  Color color,
  Object anything,
  int number,
  DateTime moment,
) {
  // expect_lint: avoid-default-tostring
  print(plain.toString());

  print(described.toString());
  print(inherited.toString());
  print(mixed.toString());
  // An abstract type dispatches to a subclass that may well describe itself.
  print(shape.toString());
  print(color.toString());
  // Nothing is known about what Object holds.
  print(anything.toString());
  print(number.toString());
  print(moment.toString());
}
