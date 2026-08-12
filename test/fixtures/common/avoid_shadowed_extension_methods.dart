class Target {
  void run() {}

  int get size => 1;
}

extension Shadowing on Target {
  void run() {}

  int get size => 2;

  void describe() {}
}

extension OnStrings on String {
  int get length => 0;

  String get shout => toUpperCase();
}
