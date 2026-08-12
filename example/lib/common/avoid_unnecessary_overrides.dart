class Base {
  int get value => 1;

  set value(int _) {}

  // expect_lint: avoid-unused-parameters
  void work(int amount, {String? label}) {}

  String describe() => 'base';

  @override
  String toString() => 'Base';
}

class ForwardsOnly extends Base {
  @override
  // expect_lint: avoid-unnecessary-overrides
  void work(int amount, {String? label}) {
    super.work(amount, label: label);
  }

  @override
  // expect_lint: avoid-unnecessary-overrides
  String describe() => super.describe();

  @override
  // expect_lint: avoid-unnecessary-overrides
  int get value => super.value;

  @override
  // expect_lint: avoid-unnecessary-overrides
  set value(int input) {
    super.value = input;
  }

  @override
  // expect_lint: avoid-unnecessary-overrides
  String toString() {
    return super.toString();
  }
}

class DoesRealWork extends Base {
  @override
  void work(int amount, {String? label}) {
    print(label);
    super.work(amount, label: label);
  }

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
  // The annotation is the point of the override, so it is not pointless.
  @Deprecated('Use describe on Base')
  @override
  String describe() => super.describe();
}
