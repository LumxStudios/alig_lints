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
    // expect_lint: avoid-misused-test-matchers
    expect(items.isEmpty, isEmpty);
    // expect_lint: avoid-misused-test-matchers
    expect(name, isTrue);
    // expect_lint: avoid-misused-test-matchers
    expect(count, isEmpty);
    // expect_lint: avoid-misused-test-matchers
    expect(name, isNull);
  });
}
