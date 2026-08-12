extension type Meters(int _value) {
  // expect_lint: avoid-renaming-representation-getters
  int get metres => _value;

  int get doubled => _value * 2;

  String describe() => '$_value m';
}

extension type Label(String _text) {
  // expect_lint: avoid-renaming-representation-getters
  String get caption => _text;

  String get shouted => _text.toUpperCase();
}

extension type Plain(int _value) {
  int get squared => _value * _value;
}
