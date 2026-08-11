// Every call supplies a real string, so the ? promises a case that never comes.
String? _pick(String text, String? fallback) => text.isEmpty ? fallback : text;

void usesPick() {
  print(_pick('a', 'b'));
  print(_pick('', 'c'));
}

class Report {
  // The body already handles the null, so removing the ? would leave a branch
  // that can never be taken. Reported, but not fixed.
  String _render(String body, int? width) => body.padRight(width ?? 0);

  void build() {
    print(_render('one', 10));
    print(_render('two', 20));
  }
}

// Omitted at one call, but the default is a real value.
String? _label(String text, {String? suffix = '!'}) =>
    text.isEmpty ? suffix : text;

void usesLabel() {
  print(_label('a'));
  print(_label('b', suffix: '?'));
}

// One caller passes null, so the parameter earns its ?.
String _greet(String name, String? title) => '${title ?? ''}$name';

void usesGreet() {
  print(_greet('a', null));
  print(_greet('b', 'Dr'));
}

// Omitting it means null, which is a nullable value.
String _describe(String text, {String? note}) => '$text${note ?? ''}';

void usesDescribe() {
  print(_describe('a', note: 'x'));
  print(_describe('b'));
}

// Public, so callers elsewhere may pass null.
String join(String text, String? separator) => '$text${separator ?? ''}';

void usesPublic() {
  print(join('a', '-'));
}
