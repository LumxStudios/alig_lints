Future<int> risky() async => throw StateError('boom');

void stored() {
  try {
    // expect_lint: avoid-uncaught-future-errors
    final pending = risky();
    print(pending.hashCode);
  } catch (error) {
    print(error);
  }
}

Future<void> awaitedLater() async {
  try {
    final pending = risky();
    print(pending.hashCode);
    await pending;
  } catch (error) {
    print(error);
  }
}

void handledOnTheFuture() {
  try {
    final pending = risky().catchError((Object error) => 0);
    print(pending.hashCode);
  } catch (error) {
    print(error);
  }
}

Future<void> awaitedImmediately() async {
  try {
    final value = await risky();
    print(value);
  } catch (error) {
    print(error);
  }
}

// Outside a try there is no catch to escape from.
void noGuard() {
  final pending = risky();
  print(pending.hashCode);
}
