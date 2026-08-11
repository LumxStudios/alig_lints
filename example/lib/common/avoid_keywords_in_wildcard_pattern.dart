String describe(Object value) {
  switch (value) {
    case int x:
      return 'int $x';
    // expect_lint: avoid-keywords-in-wildcard-pattern
    case var _:
      return 'other';
  }
}

String describeFinal(Object value) {
  switch (value) {
    // expect_lint: avoid-keywords-in-wildcard-pattern
    case final _:
      return 'anything';
  }
}

String describeTyped(Object value) {
  switch (value) {
    // expect_lint: avoid-keywords-in-wildcard-pattern
    case final int _:
      return 'an int';
    default:
      return 'other';
  }
}

String describePlain(Object value) {
  switch (value) {
    case int _:
      return 'an int';
    case _:
      return 'other';
  }
}
