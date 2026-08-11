void risky() {}

void onlyRethrow() {
  try {
    risky();
  }
  // expect_lint: avoid-only-rethrow
  catch (e) {
    rethrow;
  }
}

void onlyRethrowTyped() {
  try {
    risky();
  }
  // expect_lint: avoid-only-rethrow
  on FormatException {
    rethrow;
  }
}

void excludesTypeFromLaterHandler() {
  try {
    risky();
  } on FormatException {
    // Not redundant: this keeps the general catch below from handling format
    // errors.
    rethrow;
  } catch (e) {
    print(e);
  }
}

void doesWork() {
  try {
    risky();
  } catch (e) {
    print(e);
    rethrow;
  }
}

void stillRunsFinally() {
  try {
    risky();
  }
  // expect_lint: avoid-only-rethrow
  catch (e) {
    rethrow;
  } finally {
    print('cleanup');
  }
}
