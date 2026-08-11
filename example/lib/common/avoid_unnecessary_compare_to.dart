// This file demonstrates a different rule; its uses of first/last/single
// are incidental.
// ignore_for_file: avoid-unsafe-collection-methods

void main(List<String> args) {
  final left = args.first;
  final right = args.last;
  final a = args.length;
  final b = args.length + 1;
  final one = Duration(seconds: a);
  final two = Duration(seconds: b);
  final x = a / 2;
  final y = b / 2;
  final now = DateTime.now();
  final then = DateTime.utc(2026);

  // expect_lint: avoid-unnecessary-compare-to
  if (left.compareTo(right) == 0) print('equal strings');

  // expect_lint: avoid-unnecessary-compare-to
  if (left.compareTo(right) != 0) print('different strings');

  // expect_lint: avoid-unnecessary-compare-to
  if (0 == a.compareTo(b)) print('equal ints');

  // expect_lint: avoid-unnecessary-compare-to
  if (one.compareTo(two) == 0) print('equal durations');

  // Ordering comparisons are what compareTo is for.
  if (left.compareTo(right) > 0) print('ordered');

  // Doubles: compareTo and == disagree on NaN and -0.0.
  if (x.compareTo(y) == 0) print('double compare');

  // DateTime: compareTo ignores the isUtc flag that == checks.
  if (now.compareTo(then) == 0) print('date compare');
}
