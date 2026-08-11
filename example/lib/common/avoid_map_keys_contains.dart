class Store {
  final Map<String, int> byName = {};
}

void direct(Map<String, int> byName) {
  // Scans every key; containsKey is a hash lookup.
  // expect_lint: avoid-map-keys-contains
  if (byName.keys.contains('total')) print('present');
}

void throughField(Store store) {
  // expect_lint: avoid-map-keys-contains
  if (store.byName.keys.contains('total')) print('present');
}

// Already the direct form.
void direct2(Map<String, int> byName) {
  if (byName.containsKey('total')) print('present');
}

// values.contains has no cheaper form: containsValue scans too.
void values(Map<String, int> byName) {
  if (byName.values.contains(1)) print('present');
}

// A plain iterable, not a map's keys.
void plainList(List<String> names) {
  if (names.contains('total')) print('present');
}

// Doing something else with the keys.
void iterateKeys(Map<String, int> byName) {
  for (final key in byName.keys) {
    print(key);
  }
}
