import 'dart:async';

class Watcher {
  StreamSubscription<int>? _subscription;

  void discarded(Stream<int> source) {
    source.listen(print);
  }

  void kept(Stream<int> source) {
    _subscription = source.listen(print);
  }

  Future<void> cancel() async {
    await _subscription?.cancel();
  }
}

StreamSubscription<int> returned(Stream<int> source) => source.listen(print);

void inLocal(Stream<int> source) {
  final subscription = source.listen(print);
  print(subscription.hashCode);
}
