bool check() => true;

void main(List<String> args) {
  final flag = args.isEmpty;

  if (flag) print('and true');
  if (flag) print('or false');
  if (flag) print('true and');
  if (flag) print('false or');
  if (false) print('never');
  if (true) print('always');
  if (false) print('never either');
  if (true) print('always either');
  if (check() && false) print('call runs');
  if (flag && check()) print('real condition');
}
