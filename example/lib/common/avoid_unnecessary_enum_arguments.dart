enum Plain {
  // expect_lint: avoid-unnecessary-enum-arguments
  first(),
  // expect_lint: avoid-unnecessary-enum-arguments
  second();
}

enum WithValues {
  low(1),
  high(2);

  const WithValues(this.weight);

  final int weight;
}

enum WithOptional {
  // expect_lint: avoid-unnecessary-enum-arguments
  none(),
  double(2);

  const WithOptional([this.weight = 1]);

  final int weight;
}

enum Named {
  fromInt.of(1);

  const Named.of(this.weight);

  final int weight;
}
