class Notifier {
  final _listeners = <void Function()>[];

  void addListener(void Function() listener) => _listeners.add(listener);

  void removeListener(void Function() listener) => _listeners.remove(listener);
}

class Watcher {
  final Notifier notifier = Notifier();

  void closure() {
    // expect_lint: avoid-unremovable-callbacks-in-listeners
    notifier.addListener(() {
      print('changed');
    });
  }

  void named() {
    notifier.addListener(_onChanged);
  }

  void remove() {
    notifier.removeListener(_onChanged);
  }

  void _onChanged() {
    print('changed');
  }
}
