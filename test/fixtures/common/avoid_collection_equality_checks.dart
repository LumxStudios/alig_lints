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
  if (first == second) print('same list object');
  if (first != second) print('different list objects');
}

void maps(Map<String, int> first, Map<String, int> second) {
  if (first == second) print('same map object');
}

void nullCheck(List<int>? items) {
  if (items == null) print('none');
}

void mixed(List<int> items, Object other) {
  if (items == other) print('maybe');
}

void valueEquality(ValueList first, ValueList second) {
  if (first == second) print('equal by value');
}

void elements(List<int> items) {
  if (items.first == items.last) print('ends match');
}
