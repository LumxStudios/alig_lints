int classify(int value) {
  if (value > 0) {
    return 1;
  }
  // expect_lint: avoid-redundant-else
  else {
    return -1;
  }
}

String describe(int value) {
  if (value == 0) {
    throw ArgumentError('zero');
  }
  // expect_lint: avoid-redundant-else
  else {
    final label = 'value';
    print(label);

    return '$label $value';
  }
}

void loop(List<int> values) {
  for (final value in values) {
    if (value < 0) {
      continue;
    }
    // expect_lint: avoid-redundant-else
    else {
      print(value);
    }
  }
}

int nested(int value) {
  // Both the inner and the outer else are redundant: each sits after a branch
  // that always returns.
  if (value > 0) {
    if (value > 10) {
      return 2;
    }
    // expect_lint: avoid-redundant-else
    else {
      return 1;
    }
  }
  // expect_lint: avoid-redundant-else
  else {
    return -1;
  }
}

int keepsElse(int value) {
  var result = 0;

  // The then branch falls through, so the else is doing real work.
  if (value > 0) {
    result = 1;
  } else {
    result = -1;
  }

  return result;
}

int elseIfChain(int value) {
  // An else-if chain is left alone.
  if (value > 10) {
    return 2;
  } else if (value > 0) {
    return 1;
  }

  return 0;
}
