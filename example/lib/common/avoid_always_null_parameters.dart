// Every call passes null, so the parameter carries nothing.
// expect_lint: avoid-always-null-parameters
String _format(String text, String? prefix) => '${prefix ?? ''}$text';

void usesFormat() {
  print(_format('a', null));
  print(_format('b', null));
}

class Report {
  // expect_lint: avoid-always-null-parameters
  String _render(String body, String? footer) => '$body${footer ?? ''}';

  void build() {
    print(_render('one', null));
    print(_render('two', null));
  }
}

// A named parameter nobody ever supplies.
// expect_lint: avoid-always-null-parameters
String _label(String text, {String? suffix}) => '$text${suffix ?? ''}';

void usesLabel() {
  print(_label('a'));
  print(_label('b'));
}

// At least one call passes something.
String _greet(String name, String? title) => '${title ?? ''}$name';

void usesGreet() {
  print(_greet('a', null));
  print(_greet('b', 'Dr'));
}

// Public, so callers outside this file may pass a value.
String format(String text, String? prefix) => '${prefix ?? ''}$text';

void usesPublic() {
  print(format('a', null));
}

// Never called here, so there is nothing to conclude.
String _unused(String text, String? prefix) => '${prefix ?? ''}$text';
