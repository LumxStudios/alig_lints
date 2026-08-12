class Thing {
  Thing();

  Thing.named();
}

class Registered {
  Registered() {
    _all.add(this);
  }

  static final _all = <Registered>[];
}

void discarded() {
  Thing();
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
  Registered();
}
