bool check() => true;

void main(List<String> args) {
  final flag = args.isEmpty;

  if (flag && true) print('and true');
  if (flag || false) print('or false');
  if (true && flag) print('true and');
  if (false || flag) print('false or');
  if (flag && false) print('never');
  if (flag || true) print('always');
  if (false && flag) print('never either');
  if (true || flag) print('always either');
  if (check() && false) print('call runs');
  if (flag && check()) print('real condition');
}
