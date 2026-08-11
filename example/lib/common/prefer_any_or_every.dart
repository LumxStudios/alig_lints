bool isPositive(int value) => value > 0;

void checks(List<int> items) {
  // expect_lint: prefer-any-or-every
  if (items.where(isPositive).isNotEmpty) print('some positive');

  // expect_lint: prefer-any-or-every
  if (items.where(isPositive).isEmpty) print('none positive');

  // expect_lint: prefer-any-or-every
  if (items.where((value) => value > 10).isNotEmpty) print('some large');
}

void combined(List<int> items, bool flag) {
  // expect_lint: prefer-any-or-every
  if (flag && items.where(isPositive).isEmpty) print('flagged and none');
}

// Already the direct form.
void direct(List<int> items) {
  if (items.any(isPositive)) print('some positive');
  if (!items.any(isPositive)) print('none positive');
  if (items.every(isPositive)) print('all positive');
}

// Emptiness of the collection itself, no filter involved.
void plainEmptiness(List<int> items) {
  if (items.isNotEmpty) print('has items');
}

// where used for its result, not just its emptiness.
void usesResult(List<int> items) {
  final positive = items.where(isPositive).toList();

  print(positive);
}

// A different method in the chain.
void mapped(List<int> items) {
  if (items.map((value) => value * 2).isNotEmpty) print('mapped');
}
