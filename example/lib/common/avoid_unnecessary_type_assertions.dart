void filters(
  Iterable<String> names,
  Iterable<String?> maybeNames,
  Iterable<Object> things,
  List<int> numbers,
) {
  // expect_lint: avoid-unnecessary-type-assertions
  print(names.whereType<String>());
  // expect_lint: avoid-unnecessary-type-assertions
  print(names.whereType<Object>());
  // expect_lint: avoid-unnecessary-type-assertions
  print(numbers.nonNulls);

  // These narrow something, so they do work.
  print(things.whereType<String>());
  print(maybeNames.whereType<String>());
  print(maybeNames.nonNulls);
}
