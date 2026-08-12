// expect_lint: avoid-unnecessary-futures
Future<int> counted() async => 1;

// expect_lint: avoid-unnecessary-futures
Future<String> named(String text) async {
  return text.trim();
}

abstract class Source {
  Future<String> read();
}

class Cached implements Source {
  // Overriding an async signature is how this stays compatible.
  @override
  Future<String> read() async => 'cached';
}

// Awaits something, so the Future is carrying an actual wait.
Future<int> loaded() async => await Future<int>.value(1);

// Not async, and hands back a real future.
Future<int> delegated() => .value(1);

int plain() => 1;
