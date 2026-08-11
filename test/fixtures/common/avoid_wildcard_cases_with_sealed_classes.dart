sealed class Shape {}

class Circle extends Shape {}

class Square extends Shape {}

String describeWithWildcard(Shape shape) {
  switch (shape) {
    case Circle():
      return 'circle';
    case _:
      return 'other';
  }
}

String describeWithDefault(Shape shape) {
  switch (shape) {
    case Circle():
      return 'circle';
    default:
      return 'other';
  }
}

String describeExpression(Shape shape) => switch (shape) {
      Circle() => 'circle',
      _ => 'other',
    };

String exhaustive(Shape shape) => switch (shape) {
      Circle() => 'circle',
      Square() => 'square',
    };

class Animal {}

class Dog extends Animal {}

String describeAnimal(Animal animal) => switch (animal) {
      Dog() => 'dog',
      _ => 'other',
    };
