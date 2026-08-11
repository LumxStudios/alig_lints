String classify(int value) {
  switch (value) {
    case 1:
      return 'small';
    case 2:
      return 'medium';
    // expect_lint: no-equal-switch-case
    case 3:
      return 'small';

    // Fall-through with an empty body is the correct way to share a body.
    case 4:
    case 5:
      return 'high';

    default:
      return 'other';
  }
}

void sideEffects(int value) {
  switch (value) {
    case 1:
      print('one');
      break;
    // expect_lint: no-equal-switch-case
    case 2:
      print('one');
      break;

    // Bodies that only break are often deliberate no-ops, so they are left
    // alone even when identical.
    case 3:
      break;
    case 4:
      break;

    default:
      print('other');
  }
}
