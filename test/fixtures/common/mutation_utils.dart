class Counter {
  int value = 0;
}

void main() {
  var local = 0;
  final counter = Counter();

  if (local > 0) {
    print('reads only');
  }

  if (local > 0) {
    local = 5;
  }

  if (local > 0) {
    local++;
  }

  if (counter.value > 0) {
    counter.value = 5;
  }

  if (counter.value > 0) {
    print('reads only');
  }
}
