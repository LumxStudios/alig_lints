class Box<T> {
  Box(this.value);

  final T value;
}

void take(List<int> items) {}

final List<int> declared = [];

final Map<String, int> counts = {};

final Box<int> boxed = Box(1);

List<int> make() => [];

void uses() {
  take([]);

  // With no annotation to infer from, dropping these would give List<dynamic>.
  final inferred = <int>[];
  print(inferred);

  // The literal's type differs from the annotation, so removing the arguments
  // would change what is built.
  final List<num> widened = <int>[];
  print(widened);
}
