String _format(String text, String? prefix) => '${prefix ?? ''}$text';

void usesFormat() {
  print(_format('a', null));
  print(_format('b', null));
}

String _label(String text, {String? suffix}) => '$text${suffix ?? ''}';

void usesLabel() {
  print(_label('a'));
  print(_label('b'));
}

String _greet(String name, String? title) => '${title ?? ''}$name';

void usesGreet() {
  print(_greet('a', null));
  print(_greet('b', 'Dr'));
}

String _tearOff(String text, String? prefix) => '${prefix ?? ''}$text';

void usesTearOff() {
  final fn = _tearOff;
  print(fn('a', null));
  print(_tearOff('b', null));
}

String _withDefault(String text, {String? suffix = 'x'}) =>
    '$text${suffix ?? ''}';

void usesWithDefault() {
  print(_withDefault('a'));
}
