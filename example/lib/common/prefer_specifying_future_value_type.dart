void takeText(Future<String> _) {}

void takeCount(Future<int> _) {}

void takeMaybe(Future<String?> _) {}

void takeNothing(Future<void> _) {}

void calls(String? maybe, int? count, String text) {
  // expect_lint: prefer-specifying-future-value-type
  takeText(Future.value(maybe));

  // expect_lint: prefer-specifying-future-value-type
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
