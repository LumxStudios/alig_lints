// expect_lint: function-always-returns-null
String? alwaysNull() {
  return null;
}

// expect_lint: function-always-returns-null
String? expressionBody() => null;

// expect_lint: function-always-returns-null
String? everyBranch(bool flag) {
  if (flag) {
    return null;
  }

  return null;
}

// Falling off the end without returning is Dart's own
// body_might_complete_normally_nullable, so this rule stays out of it.

// expect_lint: function-always-returns-null
Future<String?> asyncNull() async {
  return null;
}

class Repository {
  // expect_lint: function-always-returns-null
  String? find(int id) => null;
}

abstract class Base {
  String? lookup(int id);
}

class StubbedOut extends Base {
  // The signature comes from Base, so the nullable type is not this author's
  // choice to change.
  @override
  String? lookup(int id) => null;
}

// Returns something other than null on at least one path.
String? sometimesNull(bool flag) {
  if (flag) {
    return null;
  }

  return 'value';
}

// Not nullable, so the rule does not apply.
String never() => 'value';

void nothing() {}
