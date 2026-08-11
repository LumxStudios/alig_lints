void trailing(int value) {
  print(value);
  return;
}

void onlyStatement() {
  return;
}

Future<void> asyncTrailing() async {
  print('work');
  return;
}

void earlyExit(int value) {
  if (value < 0) {
    return;
  }

  print(value);
}

int withValue(int value) {
  return value * 2;
}
