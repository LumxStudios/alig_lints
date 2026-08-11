class Box {
  int first = 0;
  int second = 0;
}

void main() {
  int a;
  int b;
  int? maybe;
  final box = Box();

  a = b = 0;
  box.first = box.second = 1;
  maybe ??= a = 2;

  a = 1;
  b = 2;
  box.first = 3;
  maybe ??= 4;

  print([a, b, maybe, box.first, box.second]);
}
