int size = 1;

class Base {
  int get size => 2;

  int scaled() => 3;
}

class Child extends Base {
  int readSize() => size;

  int readOwn() => scaled();
}

class Declaring extends Base {
  @override
  int get size => 4;

  // Declared here, so the name means the member.
  int readSize() => size;
}

extension OnBase on Base {
  // The extended type's members are not in an extension body's lexical scope, so this
  // is the global too — measured at run time.
  int readSize() => size;

  int readOther() => scaled();
}

class Unrelated {
  int readSize() => size;
}
