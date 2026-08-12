import 'dart:async';

Future<void> work() async => throw StateError('boom');

void runLater(void Function() action) => action();

void listen(Stream<int> source) {
  // expect_lint: avoid-passing-async-when-sync-expected
  source.listen((event) async {
    await work();
  });

  source.listen(print);
}

void schedules() {
  // expect_lint: avoid-passing-async-when-sync-expected
  runLater(() async {
    await work();
  });

  // expect_lint: avoid-passing-async-when-sync-expected
  Timer.run(() async {
    await work();
  });

  runLater(() {
    print('sync');
  });
}

// The parameter says it will wait, so an async function is what it wants.
void accepts(Future<void> Function() action) => action();

void passesToAwaiting() {
  accepts(() async {
    await work();
  });
}
