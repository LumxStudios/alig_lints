class Plain implements Exception {}

class Described implements Exception {
  const Described(this.reason);

  final String reason;

  @override
  String toString() => 'Described: $reason';
}

abstract class Failure implements Exception {}

void plain() {
  // expect_lint: avoid-throw-objects-without-tostring
  throw Plain();
}

void described() {
  throw Described('bad input');
}

void builtIn() {
  throw const FormatException('bad input');
}

void stateError() {
  throw StateError('bad state');
}

void indirect(Failure failure) {
  // An abstract type is never what is actually thrown; a subtype is.
  throw failure;
}
