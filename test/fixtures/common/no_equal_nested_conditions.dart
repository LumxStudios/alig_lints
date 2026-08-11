bool check() => true;

void main(List<String> args) {
  var flag = args.isEmpty;
  final count = args.length;

  if (flag) {
    if (flag) {
      print('always true');
    }
  }

  if (count > 0) {
    print('then');
  } else {
    if (count > 0) {
      print('never runs');
    }
  }

  if (flag) {
    flag = check();
    if (flag) {
      print('depends on check');
    }
  }

  if (count > 0) {
    print('a');
  } else if (count > 0) {
    print('b');
  }

  if (count > 0) {
    if (count > 1) {
      print('different');
    }
  }
}
