import 'dart:async';

void withoutTrace(Completer<int> completer, Object error) {
  // expect_lint: avoid-missing-completer-stack-trace
  completer.completeError(error);
}

void inCatch(Completer<int> completer) {
  try {
    throw StateError('bad');
  } catch (error) {
    // expect_lint: avoid-missing-completer-stack-trace
    completer.completeError(error);
  }
}

void withTrace(Completer<int> completer) {
  try {
    throw StateError('bad');
  } catch (error, stackTrace) {
    completer.completeError(error, stackTrace);
  }
}

void withCurrentTrace(Completer<int> completer, Object error) {
  completer.completeError(error, .current);
}

void completesNormally(Completer<int> completer) {
  completer.complete(1);
}
