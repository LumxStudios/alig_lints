class Box<T> {
  Box(this.value);

  final T value;
}

void take(List<int> items) {}

final List<int> declared = <int>[];

final Map<String, int> counts = <String, int>{};

final Box<int> boxed = Box<int>(1);

List<int> make() => <int>[];

void uses() {
  take(<int>[]);

  // With no annotation to infer from, dropping these would give List<dynamic>.
  final inferred = <int>[];
  print(inferred);

  // The literal's type differs from the annotation, so removing the arguments
  // would change what is built.
  final List<num> widened = <int>[];
  print(widened);
}
