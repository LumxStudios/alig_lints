dynamic topLevel = 1;

class Config {
  dynamic value;

  dynamic read() => value;

  void write(dynamic input) {
    value = input;
  }

  // A type argument is not the declaration's own type, and this one is how
  // decoded JSON arrives.
  Map<String, dynamic> toJson() => {'value': value};

  Object? readTyped() => value;
}

void locals() {
  dynamic local = 1;
  print(local);

  var inferred = 1;
  print(inferred);
}

typedef Handler = void Function(dynamic event);
