bool check() => true;

void main(List<String> args) {
  final count = args.length;
  final flag = args.isEmpty;

  if (count > 0) {
    print('a');
  } else if (flag) {
    print('b');
  } else if (count > 0) {
    print('c');
  }

  if (count > 0) {
    print('g');
  } else if (count < 0) {
    print('h');
  }

  if (check()) {
    print('i');
  } else if (check()) {
    print('j');
  }
}
