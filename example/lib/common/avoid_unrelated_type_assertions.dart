enum Status { active, archived }

class Wrapper {}

class Holder {}

void checks(int number, String text, Status status, Object thing) {
  // expect_lint: avoid-unrelated-type-assertions
  if (number is String) print('never runs');
  // expect_lint: avoid-unrelated-type-assertions
  if (text is! int) print('always runs');
  // expect_lint: avoid-unrelated-type-assertions
  if (status is Wrapper) print('never runs');

  if (thing is String) print('a real narrowing');
}

void open(Wrapper wrapper) {
  // Neither class is closed, so some third class could implement both and this
  // check is not provably impossible.
  if (wrapper is Holder) print('cannot be ruled out from here');
}

void filters(Iterable<String> names, Iterable<Object> things) {
  // expect_lint: avoid-unrelated-type-assertions
  print(names.whereType<int>());

  print(things.whereType<String>());
}
