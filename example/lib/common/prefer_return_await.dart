// expect_lint: avoid-unnecessary-futures
Future<int> risky() async => 1;

Future<int> unguarded() async {
  try {
    // expect_lint: prefer-return-await
    return risky();
  } catch (error) {
    return 0;
  }
}

Future<int> withFinally() async {
  try {
    // expect_lint: prefer-return-await
    return risky();
  } finally {
    print('done');
  }
}

// Awaited, so a failure inside risky reaches the catch.
Future<int> guarded() async {
  try {
    return await risky();
  } catch (error) {
    return 0;
  }
}

// Outside any try, returning the future directly is the cheaper path.
Future<int> passthrough() async {
  return risky();
}

// Not a future, so there is nothing to await.
// expect_lint: avoid-unnecessary-futures
Future<int> plain() async {
  try {
    return 1;
  } catch (error) {
    return 0;
  }
}
