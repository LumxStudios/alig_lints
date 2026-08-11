void takeText(Future<String> future) {}

void takeCount(Future<int> future) {}

void takeMaybe(Future<String?> future) {}

void takeNothing(Future<void> future) {}

void calls(String? maybe, int? count, String text) {
  takeText(Future.value(maybe));

  final pending = Future<int>.value(count);
  print(pending);

  // The type argument admits the null, so nothing is hidden.
  takeMaybe(Future.value(maybe));

  // A non-null argument for a non-nullable future.
  takeText(Future.value(text));

  // void accepts the absence of a value.
  takeNothing(Future.value(maybe));

  // With no argument the analyzer reports the null itself.
  takeNothing(Future.value());
}
