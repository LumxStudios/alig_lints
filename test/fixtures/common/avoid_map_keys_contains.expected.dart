class Store {
  final Map<String, int> byName = {};
}

void direct(Map<String, int> byName) {
  if (byName.containsKey('total')) print('present');
}

void throughField(Store store) {
  if (store.byName.containsKey('total')) print('present');
}

void alreadyDirect(Map<String, int> byName) {
  if (byName.containsKey('total')) print('present');
}

void values(Map<String, int> byName) {
  if (byName.values.contains(1)) print('present');
}

void plainList(List<String> names) {
  if (names.contains('total')) print('present');
}
