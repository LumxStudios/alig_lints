class User {
  String name() => 'a';

  String get label => 'b';

  void save() {}

  String greet(String other) => 'hi $other';
}

void log(Object? value) {}

void register(void Function() callback) {}

void uses(User user) {
  print(user.name());
  log(user.name());
  print('name: ${user.name()}');

  // Called, so there is nothing missing.
  print(user.name());
  print(user.label);

  // Handed to something that wants a callback, which is the point of a tear-off.
  register(user.save);

  // Takes an argument, so the call cannot be completed by adding ().
  log(user.greet);
}
