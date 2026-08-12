class Target {
  void run() {}

  int get size => 1;
}

extension Shadowing on Target {
  // expect_lint: avoid-shadowed-extension-methods
  void run() {}

  // expect_lint: avoid-shadowed-extension-methods
  int get size => 2;

  void describe() {}
}

extension OnStrings on String {
  // expect_lint: avoid-shadowed-extension-methods
  int get length => 0;

  String get shout => toUpperCase();
}
