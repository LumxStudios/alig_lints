void main() {
  final numbers = [1, 2];

  final combined = <int>[
    ...numbers,
    // expect_lint: avoid-empty-spread
    ...[],
  ];

  final unique = <int>{
    ...numbers,
    // expect_lint: avoid-empty-spread
    ...<int>{},
  };

  final byName = <String, int>{
    'a': 1,
    // expect_lint: avoid-empty-spread
    ...<String, int>{},
  };

  final nullAware = <int>[
    ...numbers,
    // expect_lint: avoid-empty-spread
    ...?[],
  ];

  // Non-empty spreads.
  final fine = <int>[...numbers, ...[3, 4]];

  print([combined, unique, byName, nullAware, fine]);
}
