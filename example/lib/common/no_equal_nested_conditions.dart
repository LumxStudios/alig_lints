bool check() => true;

void main(List<String> args) {
  var flag = args.isEmpty;
  final count = args.length;

  if (flag) {
    // expect_lint: no-equal-nested-conditions
    if (flag) {
      print('always true here');
    }
  }

  if (count > 0) {
    print('outer');
    // expect_lint: no-equal-nested-conditions
    if (count > 0) {
      print('always true here');
    }
  }

  // Inside the else branch the condition is always false.
  if (count > 0) {
    print('then');
  } else {
    // expect_lint: no-equal-nested-conditions
    if (count > 0) {
      print('never runs');
    }
  }

  // The variable is reassigned, so the inner test is meaningful.
  if (flag) {
    flag = check();
    if (flag) {
      print('depends on check');
    }
  }

  // An else-if chain is no-equal-conditions' business, not this rule's.
  if (count > 0) {
    print('a');
  }
  // expect_lint: no-equal-conditions
  else if (count > 0) {
    print('b');
  }

  // Distinct conditions.
  if (count > 0) {
    if (count > 1) {
      print('nested but different');
    }
  }
}
