void register(Function callback) => callback();

Function build() => () {};

class Registry {
  final List<Function> handlers = [];

  Function? onDone;

  void call(void Function(String) handler) => handler('ok');

  void Function()? onStart;
}

void checks(Object thing) {
  // Asking whether something is callable at all is what bare Function is for.
  if (thing is Function) print('callable');
  print(thing as Function);
}
