enum Status { active, archived }

class Wrapper {}

class Holder {}

void casts(
  int number,
  Status status,
  Object thing,
  List<String> names,
) {
  print(number as String);
  print(status as Wrapper);
  print(names.cast<int>());

  print(thing as String);
}

void open(Wrapper wrapper) {
  // Some third class could implement both, so this is not provably doomed.
  print(wrapper as Holder);
}
