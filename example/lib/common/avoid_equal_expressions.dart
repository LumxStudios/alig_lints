int roll() => 4;

void main(List<String> args) {
  final flag = args.isEmpty;
  final count = args.length;
  final int? maybe = count > 0 ? count : null;
  final mask = count;

  // expect_lint: avoid-equal-expressions
  if (flag && flag) print('and');

  // expect_lint: avoid-equal-expressions
  if (flag || flag) print('or');

  // expect_lint: avoid-equal-expressions
  print(count - count);

  // expect_lint: avoid-equal-expressions
  print(mask & mask);

  // expect_lint: avoid-equal-expressions
  print(maybe ?? maybe);

  // Doubling and squaring are ordinary arithmetic.
  print(count + count);
  print(count * count);

  // Two separate calls are not the same expression in effect.
  print(roll() - roll());

  // Comparisons belong to avoid-self-compare.
  if (count == count) print('compare');

  if (flag && count > 0) print('distinct');
}
