String describe(Object value) {
  switch (value) {
    case int x:
      return 'int $x';
    case var _:
      return 'other';
  }
}

String describeFinal(Object value) {
  switch (value) {
    case final _:
      return 'anything';
  }
}

String describeTyped(Object value) {
  switch (value) {
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
