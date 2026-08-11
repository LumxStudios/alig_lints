class Counter {
  int value = 0;

  void reset(int value) {
    this.value = this.value;
  }
}

void main() {
  var a = 1;
  a = a;
  var b = 2;
  b = a;
  print('$a $b');
}
