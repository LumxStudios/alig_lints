import 'dart:async';

Future<Future<int>> doubled() => .value(Future<int>.value(1));

class Loader {
  final Future<Future<String>>? pending = null;

  Future<Future<void>> save() => .value(Future<void>.value());
}

Future<List<Future<int>>> lists() => .value([]);

// A single layer is what a future is for.
Future<int> single() => .value(1);

// A list of futures is a collection someone will wait on together.
List<Future<int>> pendingAll() => [];

Future<Completer<int>> completer() => .value(Completer<int>());
