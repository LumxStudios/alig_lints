String dynamicType(Object? value) {
  switch (value) {
    case 1:
      return 'one';
    // dynamic matches everything a bare wildcard does, null included.
    // expect_lint: prefer-wildcard-pattern
    case dynamic _:
      return 'other';
  }
}

String nullableObject(Object? value) {
  switch (value) {
    case 1:
      return 'one';
    // expect_lint: prefer-wildcard-pattern
    case Object? _:
      return 'other';
  }
}

String nonNullableSubject(Object value) {
  switch (value) {
    case 1:
      return 'one';
    // The subject cannot be null, so Object matches exactly what _ does.
    // expect_lint: prefer-wildcard-pattern
    case Object _:
      return 'other';
  }
}

String keepsObjectOnNullableSubject(Object? value) {
  switch (value) {
    case 1:
      return 'one';
    // Object excludes null here, so this is a real test.
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

String alreadyWildcard(Object? value) => switch (value) {
      1 => 'one',
      _ => 'other',
    };
