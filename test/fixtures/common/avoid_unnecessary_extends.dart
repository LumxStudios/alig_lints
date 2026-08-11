class Plain extends Object {}

class Base {}

class Derived extends Base {}

class Box<T extends Object?> {}

class NonNull<T extends Object> {}

class Bounded<T extends num> {}

T identity<T extends Object?>(T value) => value;

typedef Mapper<T extends Object?> = T Function(T);

abstract class Repo<T extends Object?, K extends num> {
  T? find(K key);
}
