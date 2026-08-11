// Every branch says yes, so the checks decide nothing.
// expect_lint: function-always-returns-same-value
bool isValid(String input) {
  if (input.isEmpty) {
    return true;
  }
  // expect_lint: avoid-unnecessary-if
  if (input.length > 10) {
    return true;
  }

  return true;
}

// expect_lint: function-always-returns-same-value
String label(int value) {
  // expect_lint: avoid-unnecessary-if
  if (value > 0) {
    return 'unknown';
  }

  return 'unknown';
}

class Settings {
  // expect_lint: function-always-returns-same-value
  int limitFor(String key) {
    // expect_lint: avoid-unnecessary-if
    if (key.isEmpty) {
      return 10;
    }

    return 10;
  }
}

// A single constant return is a deliberate constant, not a mistake.
int zero() => 0;

bool alwaysTrue() {
  return true;
}

// Repeated nulls belong to function-always-returns-null.
// expect_lint: function-always-returns-null
String? nothing(bool flag) {
  if (flag) {
    print('flagged');

    return null;
  }

  return null;
}

// Branches that actually differ.
String describe(int value) {
  if (value > 0) {
    return 'positive';
  }

  return 'other';
}

// Not a constant.
String echo(String input) {
  // expect_lint: avoid-unnecessary-if
  if (input.isEmpty) {
    return input;
  }

  return input;
}
