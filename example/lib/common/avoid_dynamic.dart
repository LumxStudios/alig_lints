// expect_lint: avoid-dynamic
dynamic topLevel = 1;

class Config {
  // expect_lint: avoid-dynamic
  dynamic value;

  // expect_lint: avoid-dynamic
  dynamic read() => value;

  // expect_lint: avoid-dynamic
  void write(dynamic input) {
    value = input;
  }

  // A type argument is not the declaration's own type, and this one is how
  // decoded JSON arrives.
  Map<String, dynamic> toJson() => {'value': value};

  Object? readTyped() => value;
}

void locals() {
  // expect_lint: avoid-dynamic
  dynamic local = 1;
  print(local);

  var inferred = 1;
  print(inferred);
}

// expect_lint: avoid-dynamic
typedef Handler = void Function(dynamic event);
