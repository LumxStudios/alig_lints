class Configured {
  late final int _never;
  late final int _assignedInMethod;
  late int _reassigned;

  void configure() {
    _assignedInMethod = 1;
    _reassigned = 2;
  }

  int get total => _never + _assignedInMethod + _reassigned;
}

class Initialised {
  late final int _value = compute();

  int get value => _value;
}

class PublicLate {
  late final int value;

  int get doubled => value * 2;
}

int compute() => 1;
