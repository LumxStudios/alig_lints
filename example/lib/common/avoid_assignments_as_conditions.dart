final _pending = <bool>[];

// Runs out, so null is a value it really returns.
bool? nextFlag() => _pending.isEmpty ? null : _pending.removeLast();

void main() {
  var flag = false;
  bool? maybe = false;

  // expect_lint: avoid-assignments-as-conditions
  if (flag = true) print('assigned, not compared');

  // expect_lint: avoid-assignments-as-conditions
  while (flag = false) print('never runs');

  // expect_lint: avoid-assignments-as-conditions
  final label = (flag = true) ? 'yes' : 'no';

  // Nested inside a larger condition.
  // expect_lint: avoid-assignments-as-conditions
  if ((maybe = nextFlag()) != null) print('C-style idiom');

  do {
    print('once');
  }
  // expect_lint: avoid-assignments-as-conditions
  while (flag = false);

  // expect_lint: avoid-assignments-as-conditions
  for (var index = 0; flag = false; index++) {
    print(index);
  }

  // Comparisons are what conditions are for.
  if (flag == true) print('compared');
  if (maybe != null) print('checked');

  // An assignment in the update clause is not a condition.
  for (var index = 0; index < 3; index += 1) {
    print(index);
  }

  print([flag, maybe, label]);
}
