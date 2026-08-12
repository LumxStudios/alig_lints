import 'package:test/test.dart';

int counter = 0;

int increment() => ++counter;

void main() {
  test('reports repeated assertions', () {
    final result = 2 + 2;

    expect(result, 4);
    expect(result, isPositive);
    // expect_lint: avoid-duplicate-test-assertions
    expect(result, 4);
  });

  test('a differing reason does not make it a new assertion', () {
    final result = 1;

    expect(result, 1, reason: 'first check');
    // expect_lint: avoid-duplicate-test-assertions
    expect(result, 1, reason: 'second check');
  });

  test('distinct assertions are fine', () {
    expect(1, 1);
    expect(2, 2);
  });

  test('repeated calls with side effects are left alone', () {
    expect(increment(), 1);
    expect(increment(), 2);
  });

  test('assertions in separate tests are unrelated', () {
    expect(counter, isNonNegative);
  });

  test('another test with the same assertion', () {
    expect(counter, isNonNegative);
  });
}
