int roll() => 4;

void main(List<String> args) {
  final flag = args.isEmpty;
  final count = args.length;
  final int? maybe = count > 0 ? count : null;
  final mask = count;

  if (flag) print('and');
  if (flag) print('or');
  print(count - count);
  print(mask);
  print(maybe);
  print(count + count);
  print(roll() - roll());
  if (count == count) print('compare');
}
