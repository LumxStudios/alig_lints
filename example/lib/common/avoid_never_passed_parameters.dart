// expect_lint: avoid-never-passed-parameters
String _label(String text, {String suffix = '!'}) => '$text$suffix';

void usesLabel() {
  print(_label('a'));
  print(_label('b'));
}

// One caller supplies it, so the choice is real.
String _wrap(String text, {String prefix = '['}) => '$prefix$text';

void usesWrap() {
  print(_wrap('a'));
  print(_wrap('b', prefix: '('));
}

// Positional optionals count too.
// expect_lint: avoid-never-passed-parameters
String _pad(String text, [int width = 4]) => text.padLeft(width);

void usesPad() {
  print(_pad('a'));
}

// Required parameters are always supplied by definition.
String _join(String left, String right) => '$left$right';

void usesJoin() {
  print(_join('a', 'b'));
}

// Public, so callers elsewhere may supply it.
String label(String text, {String suffix = '!'}) => '$text$suffix';

void usesPublic() {
  print(label('a'));
}
