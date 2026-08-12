import 'dart:async';

Future<void> work() async => throw StateError('boom');

void runLater(void Function() action) => action();

void listen(Stream<int> source) {
  // Two rules land on this line: the callback is async where a void one is
  // wanted, and the subscription is dropped.
  source.listen((event) async {
    await work();
  });

  source.listen(print);
}

void schedules() {
  runLater(() async {
    await work();
  });

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
