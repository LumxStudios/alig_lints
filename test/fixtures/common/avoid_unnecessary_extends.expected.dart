class Plain {}

class Base {}

class Derived extends Base {}

class Box<T> {}

class NonNull<T extends Object> {}

class Bounded<T extends num> {}

T identity<T>(T value) => value;

typedef Mapper<T> = T Function(T);

abstract class Repo<T, K extends num> {
  T? find(K key);
}
