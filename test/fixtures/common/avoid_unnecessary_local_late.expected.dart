int compute() => 1;

void unconditional() {
  final int value;
  value = compute();

  print(value);
}

void bothBranches(bool flag) {
  final int value;
  if (flag) {
    value = 1;
  } else {
    value = 2;
  }

  print(value);
}

void onlyOneBranch(bool flag) {
  late final int value;
  if (flag) {
    value = 1;
  }

  print(flag ? value : 0);
}

void lazyInitializer() {
  late final value = compute();

  print(value);
}
