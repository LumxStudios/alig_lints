String classify(int value) {
  switch (value) {
    // expect_lint: avoid-duplicate-patterns
    case 1 || 1:
      return 'one';

    // A duplicate further along the chain.
    // expect_lint: avoid-duplicate-patterns
    case 4 || 5 || 4:
      return 'four or five';

    // expect_lint: avoid-duplicate-patterns
    case > 100 && > 100:
      return 'large';

    case 2 || 3:
      return 'two or three';

    case > 10 && < 20:
      return 'teens';

    default:
      return 'other';
  }
}
