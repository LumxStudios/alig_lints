// expect_lint: avoid-unused-generics
void unused<T>() => print('nothing');

// expect_lint: avoid-unused-generics
int counted<T>(int value) => value * 2;

T identity<T>(T value) => value;

List<T> wrapped<T>(T value) => [value];

int fromBody<T>() {
  final values = <T>[];

  return values.length;
}

class Holder<T> {
  Holder(this.value);

  final T value;

  // expect_lint: avoid-unused-generics
  void ignores<U>() => print(value);

  U convert<U>(U Function(T) transform) => transform(value);
}
