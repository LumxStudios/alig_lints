class Payload {}

typedef Handler = void Function();

enum Status { active }

mixin Describing {}

// expect_lint: avoid-generics-shadowing
class Holder<Payload> {
  const Holder(this.value);

  final Payload value;
}

// expect_lint: avoid-generics-shadowing
void handle<Handler>(Handler value) => print(value);

// expect_lint: avoid-generics-shadowing
class Wrapper<Status> {
  const Wrapper(this.value);

  final Status value;
}

// A name of its own shadows nothing.
class Box<T> {
  const Box(this.value);

  final T value;
}

class Pair<K, V> {
  const Pair(this.key, this.value);

  final K key;
  final V value;
}
