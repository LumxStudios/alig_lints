class User {
  String name = '';
  String email = '';
}

int compute(int seed) => seed;

void main() {
  final user = User();

  final first = user.name;
  // expect_lint: avoid-duplicate-initializers
  final second = user.name;

  final other = user.email;

  // Literals are excluded: naming the same constant twice is ordinary.
  final zero = 0;
  final origin = 0;

  // Invocations are excluded: calling twice may be intended.
  final a = compute(1);
  final b = compute(1);

  print([first, second, other, zero, origin, a, b]);
}

void separateScopes() {
  final user = User();

  if (user.name.isEmpty) {
    final label = user.name;
    print(label);
  }
  // A different block, so not the same scope.
  final label = user.name;
  print(label);
}
