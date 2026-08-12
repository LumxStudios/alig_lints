class Size {
  const Size(this.value);

  static const small = Size(1);
  static const large = Size(10);

  final int value;
}

class Job {
  const Job({required this.size});

  final Size size;
}

void argument() {
  // expect_lint: prefer-shorthands-with-static-fields, avoid-unused-instances
  Job(size: Size.small);
}

void declaration() {
  // expect_lint: prefer-shorthands-with-static-fields
  Size chosen = Size.large;

  print(chosen.value);
}

void comparison(Size size) {
  // expect_lint: prefer-shorthands-with-static-fields
  if (size == Size.small) print('small');
}

// Already shorthand.
void already() {
  // expect_lint: avoid-unused-instances
  Job(size: .small);
}

// No declared type to resolve against.
void inferred() {
  final size = Size.small;

  print(size.value);
}

// Reaching past the static field.
void member() {
  print(Size.small.value);
}
