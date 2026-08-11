void trailing(int value) {
  print(value);
}

void onlyStatement() {
}

Future<void> asyncTrailing() async {
  print('work');
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
