import 'package:test/test.dart';

void main() {
  test('parses an empty input', () {
    expect(1, 1);
  });

  // expect_lint: prefer-unique-test-names
  test('parses an empty input', () {
    expect(2, 2);
  });

  group('numbers', () {
    test('adds', () {
      expect(1, 1);
    });

    // expect_lint: prefer-unique-test-names
    test('adds', () {
      expect(2, 2);
    });
  });

  group('strings', () {
    // The same name in a different group describes a different thing.
    test('adds', () {
      expect(3, 3);
    });
  });
}
