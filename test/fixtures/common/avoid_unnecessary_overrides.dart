class Base {
  int get value => 1;

  set value(int input) {}

  void work(int amount, {String? label}) {}

  String describe() => 'base';
}

class ForwardsOnly extends Base {
  @override
  void work(int amount, {String? label}) {
    super.work(amount, label: label);
  }

  @override
  String describe() => super.describe();

  @override
  int get value => super.value;

  @override
  set value(int input) {
    super.value = input;
  }
}

class DoesRealWork extends Base {
  @override
  String describe() => 'derived: ${super.describe()}';

  @override
  int get value => super.value * 2;
}

class ChangesArguments extends Base {
  @override
  void work(int amount, {String? label}) {
    super.work(amount * 2, label: label);
  }
}

class AddsMetadata extends Base {
  @Deprecated('Use describe on Base')
  @override
  String describe() => super.describe();
}
