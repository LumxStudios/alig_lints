class WrappedError implements Exception {
  WrappedError(this.cause);

  final Object cause;
}

void risky() {}

void throwsCaught() {
  try {
    risky();
  } catch (e) {
    // Loses the original stack trace; rethrow keeps it.
    // expect_lint: avoid-throw-in-catch-block
    throw e;
  }
}

void throwsCaughtFromTypedClause() {
  try {
    risky();
  } on FormatException catch (error) {
    // expect_lint: avoid-throw-in-catch-block
    throw error;
  }
}

void rethrows() {
  try {
    risky();
  } catch (e) {
    // rethrow keeps the original trace. The catch also does something, so
    // avoid-only-rethrow has nothing to say about it either.
    print('failed: ${e.runtimeType}');
    rethrow;
  }
}

void wraps() {
  try {
    risky();
  } catch (e) {
    // Throwing a different exception is a design choice, not a lost trace.
    throw WrappedError(e);
  }
}

void throwsOutsideCatch() {
  throw WrappedError('no catch here');
}
