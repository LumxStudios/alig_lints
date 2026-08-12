class Thing {
  const Thing();

  const Thing.named();
}

class Registered {
  Registered() {
    _all.add(this);
  }

  static final _all = <Registered>[];
}

void discarded() {
  // expect_lint: avoid-unused-instances
  Thing();
  // expect_lint: avoid-unused-instances
  Thing.named();
}

void kept() {
  final thing = Thing();
  print(thing);
}

Thing produced() => Thing();

void passedOn(void Function(Thing) receive) {
  receive(Thing());
}

void sideEffects() {
  // Constructed for what the constructor does, which the rule cannot tell apart.
  // expect_lint: avoid-unused-instances
  Registered();
}
