class Point {
  // expect_lint: prefer-declaring-const-constructor
  Point(this.x, this.y);

  final int x;
  final int y;
}

class AlreadyConst {
  const AlreadyConst(this.value);

  final int value;
}

class HasMutableField {
  HasMutableField(this.value);

  int value;
}

class HasBody {
  HasBody(this.value) {
    print(value);
  }

  final int value;
}

class ComputedInitializer {
  ComputedInitializer(int value) : squared = value * value;

  final int squared;
}
