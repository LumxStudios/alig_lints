void emptyThen(List<int> items) {
  if (items.isEmpty) {
    for (final item in items) {
      print(item);
    }
  }
}

void lengthZero(List<int> items) {
  if (items.length == 0) {
    for (final item in items) {
      print(item);
    }
  }
}

void notEmptyElse(List<int> items) {
  if (items.isNotEmpty) {
    print(items.first);
  } else {
    for (final item in items) {
      print(item);
    }
  }
}

void fillsFirst(List<int> items) {
  if (items.isEmpty) {
    items.add(1);
    for (final item in items) {
      print(item);
    }
  }
}

void differentCollection(List<int> items, List<int> others) {
  if (items.isEmpty) {
    for (final other in others) {
      print(other);
    }
  }
}

void reachable(List<int> items) {
  if (items.isNotEmpty) {
    for (final item in items) {
      print(item);
    }
  }
}
