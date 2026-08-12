class Base {
  const Base(this.value);

  final int value;
}

class Shadowing extends Base {
  const Shadowing(int value) : super(value);

  @override
  int get value => 0;
}

class ShadowingSuperParameter extends Base {
  const ShadowingSuperParameter(super.value);

  @override
  int get value => 0;
}

class Passing extends Base {
  const Passing(super.value);
}

class Deriving extends Base {
  const Deriving(super.value);

  int get doubled => value * 2;
}

class NotStoring extends Base {
  const NotStoring() : super(0);

  int get label => 1;
}
