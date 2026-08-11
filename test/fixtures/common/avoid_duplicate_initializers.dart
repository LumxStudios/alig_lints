class User {
  String name = '';
  String email = '';
}

int compute(int seed) => seed;

void main() {
  final user = User();

  final first = user.name;
  final second = user.name;
  final other = user.email;

  final zero = 0;
  final origin = 0;

  final a = compute(1);
  final b = compute(1);

  print([first, second, other, zero, origin, a, b]);
}

void separateScopes() {
  final user = User();

  if (user.name.isEmpty) {
    final inner = user.name;
    print(inner);
  }
  final outer = user.name;
  print(outer);
}
