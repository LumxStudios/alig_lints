void constantIndex(List<int> items) {
  for (var index = 0; index < items.length; index++) {
    print(items[0]);
  }
}

void constantIndexInForEach(List<int> items, List<int> others) {
  for (final item in items) {
    print(others[1] + item);
  }
}

void movingIndex(List<int> items) {
  for (var index = 0; index < items.length; index++) {
    print(items[index]);
  }
}

void outsideLoop(List<int> items) {
  print(items[0]);
}

void mapLookup(Map<String, int> byName, List<int> items) {
  for (final item in items) {
    print(byName['total'] ?? item);
  }
}
