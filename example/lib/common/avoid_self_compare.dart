// This file demonstrates a different rule; its uses of first/last/single
// are incidental.
// ignore_for_file: avoid-unsafe-collection-methods

int roll() => 4;

void main(List<String> args) {
  final count = args.length;
  final name = args.first;
  final double ratio = count / 2;

  // expect_lint: avoid-self-compare
  if (count == count) print('always true');

  // expect_lint: avoid-self-compare
  if (count != count) print('always false');

  // expect_lint: avoid-self-compare
  if (count < count) print('always false');

  // expect_lint: avoid-self-compare
  if (name.length >= name.length) print('always true');

  // expect_lint: avoid-self-compare
  if (identical(name, name)) print('always true');

  // Comparing a double to itself is the idiomatic NaN test.
  if (ratio != ratio) print('NaN');

  // Two separate calls yield two values.
  if (roll() == roll()) print('maybe');

  if (count == args.length) print('distinct expressions');
}
