int compute() => 1;

class FieldFormal {
  final int value;

  FieldFormal(this.value);
}

class InitializerList {
  final int value;

  InitializerList(int input) : value = input * 2;
}

class AssignedInBody {
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
