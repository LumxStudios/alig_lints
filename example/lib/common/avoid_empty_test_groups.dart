import 'package:test/test.dart';

void main() {
  // expect_lint: avoid-empty-test-groups
  group('nothing here', () {});

  // expect_lint: avoid-empty-test-groups
  group('only setup', () {
    setUp(() {});
  });

  group('has a test', () {
    test('works', () {
      expect(1, 1);
    });
  });

  group('nested', () {
    group('inner', () {
      test('works', () {
        expect(1, 1);
      });
    });
  });
}
