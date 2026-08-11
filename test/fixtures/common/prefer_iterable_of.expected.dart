void lists(List<int> numbers) {
  final copy = List<int>.of(numbers);
  final growable = List<int>.of(numbers, growable: false);

  print([copy, growable]);
}

void sets(Set<String> names) {
  final copy = Set<String>.of(names);

  print(copy);
}

void maps(Map<String, int> byName) {
  final copy = Map<String, int>.of(byName);

  print(copy);
}

void fromDynamic(List<dynamic> values) {
  final copy = List<int>.from(values);

  print(copy);
}

void alreadyOf(List<int> numbers) {
  final copy = List<int>.of(numbers);

  print(copy);
}

void filled() {
  final zeros = List<int>.filled(3, 0);

  print(zeros);
}
