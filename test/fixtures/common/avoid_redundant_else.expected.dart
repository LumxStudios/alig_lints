int classify(int value) {
  if (value > 0) {
    return 1;
  }
  return -1;
}

String describe(int value) {
  if (value == 0) {
    throw ArgumentError('zero');
  }
  final label = 'value';
  print(label);

  return '$label $value';
}

int keepsElse(int value) {
  var result = 0;

  if (value > 0) {
    result = 1;
  } else {
    result = -1;
  }

  return result;
}
