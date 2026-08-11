void filters(
  Iterable<String> names,
  Iterable<String?> maybeNames,
  Iterable<Object> things,
  List<int> numbers,
) {
  print(names.whereType<String>());
  print(names.whereType<Object>());
  print(numbers.nonNulls);

  // These narrow something, so they do work.
  print(things.whereType<String>());
  print(maybeNames.whereType<String>());
  print(maybeNames.nonNulls);
}
