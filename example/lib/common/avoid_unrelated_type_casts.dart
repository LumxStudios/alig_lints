enum Status { active, archived }

class Wrapper {}

class Holder {}

void casts(
  int number,
  Status status,
  Object thing,
  List<String> names,
) {
  // expect_lint: avoid-unrelated-type-casts
  print(number as String);
  // expect_lint: avoid-unrelated-type-casts
  print(status as Wrapper);
  // expect_lint: avoid-unrelated-type-casts
  print(names.cast<int>());

  print(thing as String);
}

void open(Wrapper wrapper) {
  // Some third class could implement both, so this is not provably doomed.
  print(wrapper as Holder);
}
