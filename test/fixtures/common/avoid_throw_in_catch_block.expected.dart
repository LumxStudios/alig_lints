class WrappedError implements Exception {
  WrappedError(this.cause);

  final Object cause;
}

void risky() {}

void throwsCaught() {
  try {
    risky();
  } catch (e) {
    rethrow;
  }
}

void throwsCaughtFromTypedClause() {
  try {
    risky();
  } on FormatException catch (error) {
    rethrow;
  }
}

void rethrows() {
  try {
    risky();
  } catch (e) {
    rethrow;
  }
}

void wraps() {
  try {
    risky();
  } catch (e) {
    throw WrappedError(e);
  }
}
