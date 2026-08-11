void casts(
  List<String> names,
  List<Object> things,
  Map<String, int> counts,
) {
  print(names.cast<String>());
  print(counts.cast<String, int>());

  // Narrows, so the cast is what makes the call legal.
  print(things.cast<String>());
  // Widens the static type, so removing it would change what the expression is.
  print(names.cast<Object>());
}
