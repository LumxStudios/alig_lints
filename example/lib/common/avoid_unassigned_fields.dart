class Holder {
  // expect_lint: avoid-unassigned-fields
  int? _never;
  int? _assignedInMethod;
  int? _assignedInConstructor;
  final int _initialised = 1;

  Holder() {
    _assignedInConstructor = 2;
  }

  void update() {
    _assignedInMethod = 3;
  }

  int get total =>
      (_never ?? 0) +
      (_assignedInMethod ?? 0) +
      (_assignedInConstructor ?? 0) +
      _initialised;
}

class FieldFormal {
  FieldFormal(this._value);

  final int _value;

  int get value => _value;
}

class Public {
  int? never;

  int get value => never ?? 0;
}

class LateAssigned {
  late final int _value;

  void configure() {
    _value = 1;
  }

  int get value => _value;
}
