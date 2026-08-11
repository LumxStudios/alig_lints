bool check() => true;

int pick(bool flag, int a, int b) {
  return a;
}

void run(bool flag) {
  print('same');

  if (check()) {
    print('side effect');
  } else {
    print('side effect');
  }

  if (flag) {
    print('then');
  } else {
    print('else');
  }
}

int ternary(bool flag, int a, int b) {
  final same = a;
  final different = flag ? a : b;

  return same + different;
}
