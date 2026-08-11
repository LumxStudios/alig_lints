bool check() => true;

int pick(bool flag, int a, int b) {
  if (flag) {
    return a;
  } else {
    return a;
  }
}

void run(bool flag) {
  if (flag) {
    print('same');
  } else {
    print('same');
  }

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
  final same = flag ? a : a;
  final different = flag ? a : b;

  return same + different;
}
