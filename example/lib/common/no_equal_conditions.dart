bool check() => true;

void main(List<String> args) {
  final count = args.length;
  final flag = args.isEmpty;

  if (count > 0) {
    print('a');
  } else if (flag) {
    print('b');
  }
  // expect_lint: no-equal-conditions
  else if (count > 0) {
    print('c');
  }

  // Three branches, the third repeating the first.
  if (flag) {
    print('d');
  }
  // expect_lint: no-equal-conditions
  else if (flag) {
    print('e');
  } else {
    print('f');
  }

  // Distinct conditions.
  if (count > 0) {
    print('g');
  } else if (count < 0) {
    print('h');
  }

  // Two calls may return different values.
  if (check()) {
    print('i');
  } else if (check()) {
    print('j');
  }
}
