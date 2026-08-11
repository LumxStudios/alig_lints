bool hasMore() => false;

void wrongVariable(int limit) {
  var other = 0;

  for (var index = 0; index < limit; other++) {
    print(index);
  }
}

void wrongVariableDeclaredOutside(int limit) {
  var index = 0;
  var other = 0;

  for (index = 0; index < limit; other++) {
    print(index);
  }
}

void correct(int limit) {
  for (var index = 0; index < limit; index++) {
    print(index);
  }
}

void twoCounters(int limit) {
  for (var low = 0, high = limit; low < high; low++, high--) {
    print('$low $high');
  }
}

void externalCondition() {
  for (var index = 0; hasMore(); index++) {
    print(index);
  }
}

void bodyAdvances(int limit) {
  for (var index = 0; index < limit;) {
    index++;
  }
}
