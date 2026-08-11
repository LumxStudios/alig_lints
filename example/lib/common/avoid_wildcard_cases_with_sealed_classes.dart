sealed class Shape {}

class Circle extends Shape {}

class Square extends Shape {}

String describeWithWildcard(Shape shape) {
  switch (shape) {
    case Circle():
      return 'circle';
    // expect_lint: avoid-wildcard-cases-with-sealed-classes
    case _:
      return 'other';
  }
}

String describeWithDefault(Shape shape) {
  switch (shape) {
    case Circle():
      return 'circle';
    // expect_lint: avoid-wildcard-cases-with-sealed-classes
    default:
      return 'other';
  }
}

String describeExpression(Shape shape) => switch (shape) {
      Circle() => 'circle',
      // expect_lint: avoid-wildcard-cases-with-sealed-classes
      _ => 'other',
    };

String describeNullable(Shape? shape) => switch (shape) {
      Circle() => 'circle',
      null => 'none',
      // expect_lint: avoid-wildcard-cases-with-sealed-classes
      _ => 'other',
    };

// Covering every subtype keeps the compiler checking this switch.
String exhaustive(Shape shape) => switch (shape) {
      Circle() => 'circle',
      Square() => 'square',
    };

// An ordinary class hierarchy can be extended anywhere, so a wildcard is needed.
class Animal {}

class Dog extends Animal {}

String describeAnimal(Animal animal) => switch (animal) {
      Dog() => 'dog',
      _ => 'other',
    };
