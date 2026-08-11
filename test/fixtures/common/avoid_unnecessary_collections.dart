int compute() => 1;

void accessors(int value) {
  print([value].first);
  print([value].single);
  print({value}.single);
  print([compute()].first);
}

void spreads(int value, List<int> others) {
  final combined = <int>[...[value], ...others];

  print(combined);
}

void severalElements(int first, int second) {
  print([first, second].first);
}

void realCollection(List<int> items) {
  print(items.first);
}

List<int> singleton(int value) => [value];
