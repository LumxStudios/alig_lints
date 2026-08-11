enum Color { red, green }

class Size {
  const Size(this.value);

  const Size.large() : value = 10;

  static const small = Size(1);

  static Size of(int value) => Size(value);

  final int value;
}

// expect_lint: prefer-returning-shorthands
Color favourite() => Color.red;

// expect_lint: prefer-returning-shorthands
Size smallest() => Size.small;

// expect_lint: prefer-returning-shorthands
Size sized(int value) => Size.of(value);

// expect_lint: prefer-returning-shorthands
Size large() => Size.large();

// An unnamed constructor would only become `.new(value)`, so it is left alone.
Size made(int value) => Size(value);

class Theme {
  // expect_lint: prefer-returning-shorthands
  Color get accent => Color.green;
}

// Already a shorthand.
Color already() => .red;

// The value does not come from the return type's own namespace.
Color fromVariable(Color value) => value;

// A block body is out of scope: this rule is about expression bodies.
Color blockBody() {
  return Color.red;
}

// The return type is not what is being named.
String describe() => Color.red.name;
