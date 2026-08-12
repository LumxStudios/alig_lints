class Base {
  const Base();

  const Base.named(int value);

  void greet() {}

  void log(String _) {}
}

mixin Extra {
  void greet() {}
}

class RedundantSuperCall extends Base {
  // expect_lint: avoid-unnecessary-super
  RedundantSuperCall() : super();
}

class RedundantWithOtherInitializer extends Base {
  final int value;

  // expect_lint: avoid-unnecessary-super
  RedundantWithOtherInitializer(this.value) : super();
}

class KeepsSuperCall extends Base {
  KeepsSuperCall() : super.named(1);
}

class RedundantSuperPrefix extends Base {
  void work() {
    // This class does not declare log, so the prefix resolves to the same
    // member either way.
    // expect_lint: avoid-unnecessary-super
    super.log('working');
  }
}

class KeepsPrefixWhenOverriding extends Base {
  @override
  void log(String message) {
    // Removing the prefix here would call this method recursively.
    super.log('prefixed: $message');
  }
}

class KeepsPrefixWithMixin extends Base with Extra {
  void work() {
    // A mixin also provides greet, so the prefix chooses between them.
    super.greet();
  }
}
