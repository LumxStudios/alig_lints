enum Status { active, archived }

class Wrapper {}

class Holder {}

void checks(int number, String text, Status status, Object thing) {
  if (number is String) print('never runs');
  if (text is! int) print('always runs');
  if (status is Wrapper) print('never runs');

  if (thing is String) print('a real narrowing');
}

void open(Wrapper wrapper) {
  // Neither class is closed, so some third class could implement both and this
  // check is not provably impossible.
  if (wrapper is Holder) print('cannot be ruled out from here');
}

void filters(Iterable<String> names, Iterable<Object> things) {
  print(names.whereType<int>());

  print(things.whereType<String>());
}
