class Box {
  int value = 0;

  int get doubled => value * 2;

  void work() {}
}

int compute() => 1;

void main() {
  final box = Box();
  var count = 0;

  // expect_lint: avoid-unnecessary-statements
  count;

  // expect_lint: avoid-unnecessary-statements
  box.value;

  // expect_lint: avoid-unnecessary-statements
  count + 1;

  // expect_lint: avoid-unnecessary-statements
  box is Box;

  // expect_lint: avoid-unnecessary-statements
  count > 0 ? count : 0;

  // Statements that do something.
  box.work();
  count = compute();
  count++;
  Box();
  print(box.doubled);
}
