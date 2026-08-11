class Base {
  Base();

  Base.named(int value);

  void log(String message) {}
}

class RedundantSuperCall extends Base {
  RedundantSuperCall();
}

class RedundantWithOtherInitializer extends Base {
  final int value;

  RedundantWithOtherInitializer(this.value);
}

class KeepsSuperCall extends Base {
  KeepsSuperCall() : super.named(1);
}

class RedundantSuperPrefix extends Base {
  void work() {
    log('working');
  }
}

class KeepsPrefixWhenOverriding extends Base {
  @override
  void log(String message) {
    super.log('prefixed: $message');
  }
}
