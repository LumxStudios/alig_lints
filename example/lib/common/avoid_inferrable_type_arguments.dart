class Box<T> {
  const Box(this.value);

  final T value;
}

void take(List<int> _) {}

// expect_lint: avoid-inferrable-type-arguments
final List<int> declared = <int>[];

// expect_lint: avoid-inferrable-type-arguments
final Map<String, int> counts = <String, int>{};

// expect_lint: avoid-inferrable-type-arguments
final Box<int> boxed = Box<int>(1);

// expect_lint: avoid-inferrable-type-arguments
List<int> make() => <int>[];

void uses() {
  // expect_lint: avoid-inferrable-type-arguments
  take(<int>[]);

  // With no annotation to infer from, dropping these would give List<dynamic>.
  final inferred = <int>[];
  print(inferred);

  // The literal's type differs from the annotation, so removing the arguments
  // would change what is built.
  final List<num> widened = <int>[];
  print(widened);
}
