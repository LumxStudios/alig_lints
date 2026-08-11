void risky() {}

void onlyRethrow() {
  try {
    risky();
  } catch (e) {
    rethrow;
  }
}

void excludesTypeFromLaterHandler() {
  try {
    risky();
  } on FormatException {
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
  } catch (e) {
    rethrow;
  } finally {
    print('cleanup');
  }
}
