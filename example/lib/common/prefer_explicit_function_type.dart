// expect_lint: prefer-explicit-function-type
void register(Function callback) => callback();

// expect_lint: prefer-explicit-function-type
Function build() => () {};

class Registry {
  // expect_lint: prefer-explicit-function-type
  final List<Function> handlers = [];

  // expect_lint: prefer-explicit-function-type
  Function? onDone;

  void call(void Function(String) handler) => handler('ok');

  void Function()? onStart;
}

void checks(Object thing) {
  // Asking whether something is callable at all is what bare Function is for.
  if (thing is Function) print('callable');
  print(thing as Function);
}
