int compute() => 1;

class FieldFormal {
  // expect_lint: avoid-unnecessary-late-fields
  late final int value;

  FieldFormal(this.value);
}

class InitializerList {
  // expect_lint: avoid-unnecessary-late-fields
  late final int value;

  InitializerList(int input) : value = input * 2;
}

class EveryConstructor {
  // expect_lint: avoid-unnecessary-late-fields
  late final int value;

  EveryConstructor(this.value);

  EveryConstructor.zero() : value = 0;
}

class AssignedInBody {
  // A non-late final field cannot be assigned in a body, so late is required.
  late final int value;

  AssignedInBody(int input) {
    value = input * 2;
  }
}

class OneConstructorMisses {
  late final int value;

  OneConstructorMisses(this.value);

  OneConstructorMisses.lazy();
}

class NoConstructor {
  late final int value;
}

class LazyInitialized {
  late final int value = compute();
}
