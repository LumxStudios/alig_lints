void main(List<String> args) {
  final count = args.length;

  if (1 < 2) print('always');
  if (3 == 4) print('never');
  if ('a' != 'b') print('always');
  final flag = 10 >= 20;

  if (1 == 1) print('self');
  if (true && count > 0) print('literal chain');
  assert(2 < 3, 'always passes');

  if (count > 0) print('real');

  print(flag);
}
