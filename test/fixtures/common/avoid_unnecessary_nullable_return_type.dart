String? label(bool short) => short ? 'S' : 'long';

String? pick(bool first) {
  if (first) return 'a';

  return 'b';
}

Future<String?> load() async => 'ready';

// Falling off the end returns null, so the ? is doing work.
String? maybe(bool found) {
  if (found) return 'a';

  return null;
}

// The last statement is not a return, so the function can end without one.
String? fallsThrough(bool found) {
  if (found) {
    return 'a';
  }

  return null;
}

String? fromNullable(String? source) => source;

class Store {
  static String? key() => 'k';

  // An instance method a subclass elsewhere may override with a nullable
  // return; reported, but not fixed.
  String? name() => 'store';
}

final class Sealed {
  String? name() => 'sealed';
}

abstract class Source {
  String? read();
}
