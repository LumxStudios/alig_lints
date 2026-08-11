String? alwaysNull() {
  return null;
}

String? expressionBody() => null;

String? everyBranch(bool flag) {
  if (flag) {
    print('flagged');

    return null;
  }

  return null;
}

Future<String?> asyncNull() async {
  return null;
}

class Repository {
  String? find(int id) => null;
}

abstract class Base {
  String? lookup(int id);
}

class StubbedOut extends Base {
  @override
  String? lookup(int id) => null;
}

String? sometimesNull(bool flag) {
  if (flag) {
    return null;
  }

  return 'value';
}

String never() => 'value';

void nothing() {}
