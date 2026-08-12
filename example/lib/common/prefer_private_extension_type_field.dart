// expect_lint: prefer-private-extension-type-field
extension type Meters(int value) {
  String describe() => '$value m';
}

extension type Label(String _text) {
  String get shouted => _text.toUpperCase();
}
