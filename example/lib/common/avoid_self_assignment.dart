class Counter {
  int value = 0;
  int other = 0;

  void bad() {
    // expect_lint: avoid-self-assignment
    this.value = this.value;
  }

  void good() {
    value = other;
  }
}

class Nested {
  Counter counter = Counter();

  void bad() {
    // expect_lint: avoid-self-assignment
    counter.value = counter.value;
  }

  void good() {
    counter.value = counter.other;
  }
}

void main() {
  var a = 1;

  // Incidental to this rule but a real finding: 2 is overwritten below without
  // ever being read.
  // expect_lint: avoid-unnecessary-reassignment
  var b = 2;

  // expect_lint: avoid-self-assignment
  a = a;

  b = a;
  a += a;
  print('$a $b');
}
