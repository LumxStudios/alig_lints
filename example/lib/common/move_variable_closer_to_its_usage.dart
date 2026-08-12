void onlyInnerUse(bool flag) {
  // expect_lint: move-variable-closer-to-its-usage
  final message = compute();
  if (flag) {
    print(message);
  }
}

void usedInBothBlocks(bool flag) {
  final message = compute();
  if (flag) {
    print(message);
  }
  print(message);
}

void usedInTwoInnerBlocks(bool flag) {
  final message = compute();
  if (flag) {
    print(message);
  } else {
    print('$message!');
  }
}

void declaredWhereUsed(bool flag) {
  if (flag) {
    final message = compute();
    print(message);
  }
}

String compute() => 'x';
