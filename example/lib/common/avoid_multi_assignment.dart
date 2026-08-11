class Box {
  int first = 0;
  int second = 0;
}

void main() {
  int a;
  int b;
  int? maybe;
  final box = Box();

  // Also a real finding: a's value here is overwritten below without being
  // read, which avoid-unnecessary-reassignment reports.
  // expect_lint: avoid-multi-assignment, avoid-unnecessary-reassignment
  a = b = 0;

  // expect_lint: avoid-multi-assignment
  box.first = box.second = 1;

  // expect_lint: avoid-multi-assignment
  maybe ??= a = 2;

  // One target per statement.
  a = 1;
  b = 2;
  box.first = 3;
  maybe ??= 4;

  print([a, b, maybe, box.first, box.second]);
}
