void main(List<String> args) {
  for (final arg in args) {
    print(arg);
    // expect_lint: avoid-unnecessary-continue
    continue;
  }

  var index = 0;
  while (index < args.length) {
    index++;
    // expect_lint: avoid-unnecessary-continue
    continue;
  }

  do {
    index--;
    // expect_lint: avoid-unnecessary-continue
    continue;
  } while (index > 0);

  // A continue that skips the rest of the body is doing work.
  for (final arg in args) {
    if (arg.isEmpty) {
      continue;
    }
    print(arg);
  }

  // A labelled continue targets an outer loop and cannot be dropped.
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
