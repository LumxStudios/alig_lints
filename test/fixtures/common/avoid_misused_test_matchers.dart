import 'package:test/test.dart';

void main() {
  final items = <int>[1, 2];
  const name = 'a';
  const count = 2;

  test('matchers that fit the value', () {
    expect(items, isNotEmpty);
    expect(items.isEmpty, isFalse);
    expect(name, 'a');
    expect(count, 2);
  });

  test('matchers that do not', () {
    expect(items.isEmpty, isEmpty);
    expect(name, isTrue);
    expect(count, isEmpty);
    expect(name, isNull);
  });
}
