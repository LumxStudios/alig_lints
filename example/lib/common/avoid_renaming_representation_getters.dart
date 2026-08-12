extension type Meters(int value) {
  // expect_lint: avoid-renaming-representation-getters
  int get metres => value;

  int get doubled => value * 2;

  String describe() => '$value m';
}

extension type Label(String text) {
  // expect_lint: avoid-renaming-representation-getters
  String get caption => text;

  String get shouted => text.toUpperCase();
}

extension type Plain(int value) {
  int get squared => value * value;
}
