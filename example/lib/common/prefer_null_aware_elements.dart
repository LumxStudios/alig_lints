List<int> listElement(int? value) {
  // expect_lint: prefer-null-aware-elements
  return [if (value != null) value];
}

Set<int> setElement(int? value) {
  // expect_lint: prefer-null-aware-elements
  return {if (value != null) value};
}

Map<String, int> mapValue(int? value) {
  // expect_lint: prefer-null-aware-elements
  return {if (value != null) 'total': value};
}

List<int> withBang(int? value) {
  // expect_lint: prefer-null-aware-elements
  return [if (value != null) value!];
}

// An else branch cannot be written as ?element.
List<int> withElse(int? value) => [if (value != null) value else 0];

// The element is not the value being tested.
List<int> different(int? value, int other) => [if (value != null) other];

// Not a null check.
List<int> notNullCheck(bool flag, int value) => [if (flag) value];

// Already null-aware.
List<int> already(int? value) => [?value];

// A plain element.
List<int> plain(int value) => [value];
