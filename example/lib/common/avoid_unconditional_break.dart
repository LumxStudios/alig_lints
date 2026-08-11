// This file demonstrates a different rule; its uses of first/last/single
// are incidental.
// ignore_for_file: avoid-unsafe-collection-methods

String? firstArg(List<String> args) {
  for (final arg in args) {
    print(arg);
    // The loop can never reach a second iteration.
    // expect_lint: avoid-unconditional-break
    break;
  }

  return args.isEmpty ? null : args.first;
}

String? returnsImmediately(List<String> args) {
  for (final arg in args) {
    // expect_lint: avoid-unconditional-break
    return arg;
  }

  return null;
}

void throwsImmediately(List<String> args) {
  for (final arg in args) {
    // expect_lint: avoid-unconditional-break
    throw StateError('never iterates: $arg');
  }
}

void whileLoop(List<String> args) {
  var index = 0;
  while (index < args.length) {
    print(args[index]);
    index++;
    // expect_lint: avoid-unconditional-break
    break;
  }
}

void continueInTheMiddle(List<String> args) {
  for (final arg in args) {
    // Something follows, so this continue makes it unreachable. A continue with
    // nothing after it is avoid-unnecessary-continue's instead.
    // expect_lint: avoid-unconditional-break
    continue;
    print(arg);
  }
}

// Conditional exits are what loops are for.
String? findFirstEmpty(List<String> args) {
  for (final arg in args) {
    if (arg.isEmpty) {
      return arg;
    }
  }

  return null;
}

void breaksOnCondition(List<String> args) {
  for (final arg in args) {
    if (arg == 'stop') break;
    print(arg);
  }
}

// A break inside a switch leaves the switch, not the loop.
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

// A trailing continue is avoid-unnecessary-continue's business.
void trailingContinue(List<String> args) {
  for (final arg in args) {
    print(arg);
    // expect_lint: avoid-unnecessary-continue
    continue;
  }
}
