// A collection type that defines value equality is compared safely.
class ValueList {
  const ValueList(this.items);

  final List<int> items;

  @override
  bool operator ==(Object other) =>
      other is ValueList && other.items.length == items.length;

  @override
  int get hashCode => items.length;
}

void lists(List<int> first, List<int> second) {
  // Compares references, not contents.
  // expect_lint: avoid-collection-equality-checks
  if (first == second) print('same list object');

  // expect_lint: avoid-collection-equality-checks
  if (first != second) print('different list objects');
}

void sets(Set<String> first, Set<String> second) {
  // expect_lint: avoid-collection-equality-checks
  if (first == second) print('same set object');
}

void maps(Map<String, int> first, Map<String, int> second) {
  // expect_lint: avoid-collection-equality-checks
  if (first == second) print('same map object');
}

void iterables(Iterable<int> first, Iterable<int> second) {
  // expect_lint: avoid-collection-equality-checks
  if (first == second) print('same iterable object');
}

// A null check is not a collection comparison.
void nullCheck(List<int>? items) {
  if (items == null) print('none');
}

// One side is not a collection.
void mixed(List<int> items, Object other) {
  if (items == other) print('maybe');
}

// The type defines its own equality, so == means what it says.
void valueEquality(ValueList first, ValueList second) {
  if (first == second) print('equal by value');
}

// Comparing elements, not collections.
void elements(List<int> items) {
  if (items.first == items.last) print('ends match');
}
