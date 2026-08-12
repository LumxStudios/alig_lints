import 'package:test/test.dart';

void main() {
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
