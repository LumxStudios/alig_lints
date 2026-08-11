void main(List<String> args) {
  final flag = args.isEmpty;
  final count = args.length;
  final Object value = count;
  final double ratio = count / 2;

  if (!!flag) print('double negation');
  if (!(count == 1)) print('not equal');
  if (!(count != 1)) print('equal');
  if (!(value is String)) print('not a string');
  if (!(value is! String)) print('is a string');
  if (!(ratio < 1)) print('not less');
  if (!flag) print('plain');
  if (!(flag && count > 0)) print('neither');
}
