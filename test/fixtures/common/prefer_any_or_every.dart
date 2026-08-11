bool isPositive(int value) => value > 0;

void checks(List<int> items) {
  if (items.where(isPositive).isNotEmpty) print('some positive');
  if (items.where(isPositive).isEmpty) print('none positive');
  if (items.where((value) => value > 10).isNotEmpty) print('some large');
}

void combined(List<int> items, bool flag) {
  if (flag && items.where(isPositive).isEmpty) print('flagged and none');
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
