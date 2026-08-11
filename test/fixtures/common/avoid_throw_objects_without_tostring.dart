class Plain implements Exception {}

class Described implements Exception {
  Described(this.reason);

  final String reason;

  @override
  String toString() => 'Described: $reason';
}

abstract class Failure implements Exception {}

void plain() {
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
