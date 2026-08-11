int roll() => 4;

void main(List<String> args) {
  final count = args.length;
  final name = args.first;
  final double ratio = count / 2;

  if (count == count) print('always true');
  if (count != count) print('always false');
  if (count < count) print('always false');
  if (name.length >= name.length) print('always true');
  if (identical(name, name)) print('always true');
  if (ratio != ratio) print('NaN');
  if (roll() == roll()) print('maybe');
  if (count == args.length) print('distinct');
}
