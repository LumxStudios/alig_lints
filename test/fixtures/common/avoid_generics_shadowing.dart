class Payload {}

typedef Handler = void Function();

enum Status { active }

mixin Describing {}

class Holder<Payload> {
  Holder(this.value);

  final Payload value;
}

void handle<Handler>(Handler value) => print(value);

class Wrapper<Status> {
  Wrapper(this.value);

  final Status value;
}

// A name of its own shadows nothing.
class Box<T> {
  Box(this.value);

  final T value;
}

class Pair<K, V> {
  Pair(this.key, this.value);

  final K key;
  final V value;
}
