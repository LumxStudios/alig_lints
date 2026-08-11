const flag = true;

void main() {
  final byName = <String, int>{
    'alpha': 1,
    'beta': 2,
    // expect_lint: avoid-duplicate-map-keys
    'alpha': 3,
  };

  final byNumber = <int, String>{
    1: 'one',
    // expect_lint: avoid-duplicate-map-keys
    1: 'uno',
  };

  // Distinct keys.
  final fine = <String, int>{'a': 1, 'b': 2};

  // Equal-looking keys of different types stay distinct.
  final mixed = <Object, int>{0: 1, '0': 2};

  // Conditional entries are not statically comparable.
  final conditional = <String, int>{
    'a': 1,
    if (flag) 'a': 2,
  };

  print([byName, byNumber, fine, mixed, conditional]);
}
