extension type Meters(int value) {
  int get metres => value;

  int get doubled => value * 2;

  String describe() => '$value m';
}

extension type Label(String text) {
  String get caption => text;

  String get shouted => text.toUpperCase();
}

extension type Plain(int value) {
  int get squared => value * value;
}
