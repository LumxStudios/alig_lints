// expect_lint: avoid-unnecessary-extends
class Plain extends Object {}

class Base {}

class Derived extends Base {}

// The default bound for a type parameter is Object?, so this adds nothing.
// expect_lint: avoid-unnecessary-extends
class Box<T extends Object?> {}

// A non-nullable bound is a real constraint, not the default.
class NonNull<T extends Object> {}

class Bounded<T extends num> {}

// expect_lint: avoid-unnecessary-extends
T identity<T extends Object?>(T value) => value;

// expect_lint: avoid-unnecessary-extends
typedef Mapper<T extends Object?> = T Function(T);

// Only the redundant bound of T is reported; K's is a real constraint.
// expect_lint: avoid-unnecessary-extends
abstract class Repo<T extends Object?, K extends num> {
  T? find(K key);
}
