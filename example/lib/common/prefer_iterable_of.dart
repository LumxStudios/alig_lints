void lists(List<int> numbers) {
  // from() accepts any iterable, so a wrong element type only fails at runtime.
  // expect_lint: prefer-iterable-of
  final copy = List<int>.from(numbers);

  // expect_lint: prefer-iterable-of
  final growable = List<int>.from(numbers, growable: false);

  print([copy, growable]);
}

void sets(Set<String> names) {
  // expect_lint: prefer-iterable-of
  final copy = Set<String>.from(names);

  print(copy);
}

void maps(Map<String, int> byName) {
  // expect_lint: prefer-iterable-of
  final copy = Map<String, int>.from(byName);

  print(copy);
}

// Reported, but not auto-fixed: of() would not compile from a dynamic source.
void fromDynamic(List<dynamic> values) {
  // expect_lint: prefer-iterable-of
  final copy = List<int>.from(values);

  print(copy);
}

// Already the safe form.
void alreadyOf(List<int> numbers) {
  final copy = List<int>.of(numbers);

  print(copy);
}

// A different constructor.
void filled() {
  final zeros = List<int>.filled(3, 0);

  print(zeros);
}

// Not a core collection.
class Registry {
  const Registry.from(this.name);

  final String name;
}

void custom() {
  print(Registry.from('a').name);
}
