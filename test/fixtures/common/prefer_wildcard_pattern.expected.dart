String dynamicType(Object? value) {
  switch (value) {
    case 1:
      return 'one';
    case _:
      return 'other';
  }
}

String nullableObject(Object? value) {
  switch (value) {
    case 1:
      return 'one';
    case _:
      return 'other';
  }
}

String nonNullableSubject(Object value) {
  switch (value) {
    case 1:
      return 'one';
    case _:
      return 'other';
  }
}

String keepsObjectOnNullableSubject(Object? value) {
  switch (value) {
    case 1:
      return 'one';
    case Object _:
      return 'not null';
    case null:
      return 'null';
  }
}

String realTypeTest(Object? value) {
  switch (value) {
    case int _:
      return 'an int';
    case _:
      return 'other';
  }
}
