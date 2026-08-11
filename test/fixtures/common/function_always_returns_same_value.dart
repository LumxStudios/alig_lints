bool isValid(String input) {
  if (input.isEmpty) {
    return true;
  }
  if (input.length > 10) {
    return true;
  }

  return true;
}

String label(int value) {
  if (value > 0) {
    return 'unknown';
  }

  return 'unknown';
}

class Settings {
  int limitFor(String key) {
    if (key.isEmpty) {
      return 10;
    }

    return 10;
  }
}

int zero() => 0;

bool alwaysTrue() {
  return true;
}

String describe(int value) {
  if (value > 0) {
    return 'positive';
  }

  return 'other';
}

String echo(String input) {
  if (input.isEmpty) {
    return input;
  }

  return input;
}
