void risky() {}

void run(bool flag) {
  // expect_lint: no-empty-block
  if (flag) {}

  if (flag) {
    print('then');
  }
  // expect_lint: no-empty-block
  else {}

  // expect_lint: no-empty-block
  while (flag) {}

  // expect_lint: no-empty-block
  for (var index = 0; index < 3; index++) {}

  // expect_lint: no-empty-block
  for (final item in <int>[]) {}

  // expect_lint: no-empty-block
  do {} while (flag);

  // expect_lint: no-empty-block
  try {} catch (e) {
    print(e);
  }

  try {
    risky();
  }
  // expect_lint: no-empty-block
  finally {}

  // A bare block used for scoping.
  // expect_lint: no-empty-block
  {}

  // An empty catch is how you deliberately swallow an exception, and Dart's own
  // empty_catches already reports it.
  try {
    risky();
  } catch (e) {}

  // Blocks with something in them.
  if (flag) {
    print('ok');
  }
}

// Empty function bodies are ordinary: no-op callbacks, empty constructors,
// stubs. Dart's empty_constructor_bodies covers the constructor case.
void noop() {}

class Service {
  Service() {}

  void onEvent() {}
}
