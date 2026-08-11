bool isPositive(int value) => value > 0;

void checks(List<int> items) {
  if (items.any(isPositive)) print('some positive');
  if (!items.any(isPositive)) print('none positive');
  if (items.any((value) => value > 10)) print('some large');
}

void combined(List<int> items, bool flag) {
  if (flag && !items.any(isPositive)) print('flagged and none');
}

void direct(List<int> items) {
  if (items.any(isPositive)) print('some positive');
}

void plainEmptiness(List<int> items) {
  if (items.isNotEmpty) print('has items');
}

void mapped(List<int> items) {
  if (items.map((value) => value * 2).isNotEmpty) print('mapped');
}
