bool check() => true;

int classify(int value) {
  if (value > 0) {
    return 0;
  }

  return 0;
}

void earlyExit(int value) {
  if (value < 0) {
    return;
  }

  return;
}

int sideEffectCondition(int value) {
  if (check()) {
    return 1;
  }

  return 1;
}

int keepsIf(int value) {
  if (value > 0) {
    return 1;
  }

  return 0;
}
