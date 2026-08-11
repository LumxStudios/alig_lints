void main(List<String> args) {
  for (final arg in args) {
    print(arg);
  }

  var index = 0;
  while (index < args.length) {
    index++;
  }

  for (final arg in args) {
    if (arg.isEmpty) {
      continue;
    }
    print(arg);
  }

  outer:
  for (final arg in args) {
    for (final char in arg.split('')) {
      if (char == 'x') {
        continue outer;
      }
      print(char);
    }
  }
}
