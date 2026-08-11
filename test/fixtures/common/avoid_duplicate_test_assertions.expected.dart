import 'package:test/test.dart';

int counter = 0;

int increment() => ++counter;

void main() {
  test('repeats an assertion', () {
    final result = 4;
    expect(result, 4);
    expect(result, isPositive);
  });

  test('differing reasons', () {
    expect(1, 1, reason: 'first');
  });

  test('side effects are left alone', () {
    expect(increment(), 1);
    expect(increment(), 2);
  });
}
