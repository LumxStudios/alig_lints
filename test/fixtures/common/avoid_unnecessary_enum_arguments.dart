enum Plain {
  first(),
  second();
}

enum WithValues {
  low(1),
  high(2);

  const WithValues(this.weight);

  final int weight;
}

enum Named {
  fromInt.of(1);

  const Named.of(this.weight);

  final int weight;
}
