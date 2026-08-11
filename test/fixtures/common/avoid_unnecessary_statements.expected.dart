class Box {
  int value = 0;

  void work() {}
}

int compute() => 1;

void main() {
  final box = Box();
  var count = 0;

  box.work();
  count = compute();
  count++;
  Box();
  print(count);
}
