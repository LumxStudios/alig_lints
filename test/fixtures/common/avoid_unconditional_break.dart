String? firstArg(List<String> args) {
  for (final arg in args) {
    print(arg);
    break;
  }

  return args.isEmpty ? null : args.first;
}

String? returnsImmediately(List<String> args) {
  for (final arg in args) {
    return arg;
  }

  return null;
}

void whileLoop(List<String> args) {
  var index = 0;
  while (index < args.length) {
    index++;
    break;
  }
}

String? findFirstEmpty(List<String> args) {
  for (final arg in args) {
    if (arg.isEmpty) {
      return arg;
    }
  }

  return null;
}

void switchInLoop(List<String> args) {
  for (final arg in args) {
    switch (arg) {
      case 'a':
        print('a');
        break;
      default:
        print('other');
    }
  }
}

void trailingContinue(List<String> args) {
  for (final arg in args) {
    print(arg);
    continue;
  }
}
