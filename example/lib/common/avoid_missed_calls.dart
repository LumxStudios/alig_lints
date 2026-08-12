class User {
  String name() => 'a';

  String get label => 'b';

  void save() {}

  String greet(String other) => 'hi $other';
}

void log(Object? value) {}

void register(void Function() callback) {}

void uses(User user) {
  // expect_lint: avoid-missed-calls
  print(user.name);
  // expect_lint: avoid-missed-calls
  log(user.name);
  // expect_lint: avoid-missed-calls
  print('name: ${user.name}');

  // Called, so there is nothing missing.
  print(user.name());
  print(user.label);

  // Handed to something that wants a callback, which is the point of a tear-off.
  register(user.save);

  // Reported too, but with no fix: the call cannot be completed by adding ()
  // without deciding what to pass.
  // expect_lint: avoid-missed-calls
  log(user.greet);
}
