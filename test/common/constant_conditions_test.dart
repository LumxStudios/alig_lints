import 'package:alig_lints/src/common/constant_conditions.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:test/test.dart';

/// Parses `var _x = <source>;` and returns the initializer expression.
Expression parseExpression(String source) {
  final unit = parseString(content: 'var _x = $source;').unit;
  final declaration = unit.declarations.single as TopLevelVariableDeclaration;

  return declaration.variables.variables.single.initializer!;
}

bool? valueOf(String source) => constantBoolValueOf(parseExpression(source));

void main() {
  test('folds boolean literals and negation', () {
    expect(valueOf('true'), isTrue);
    expect(valueOf('false'), isFalse);
    expect(valueOf('!true'), isFalse);
    expect(valueOf('!(!false)'), isFalse);
  });

  test('folds logical operators, including one decisive side', () {
    expect(valueOf('true && true'), isTrue);
    expect(valueOf('false && flag'), isFalse);
    expect(valueOf('flag && false'), isFalse);
    expect(valueOf('true || flag'), isTrue);
    expect(valueOf('false || false'), isFalse);
  });

  test('folds comparisons between literals', () {
    expect(valueOf('1 == 1'), isTrue);
    expect(valueOf('1 == 2'), isFalse);
    expect(valueOf("'a' == 'a'"), isTrue);
    expect(valueOf('1 < 2'), isTrue);
    expect(valueOf('2 <= 1'), isFalse);
  });

  test('returns null for anything not syntactically constant', () {
    expect(valueOf('flag'), isNull);
    expect(valueOf('flag && other'), isNull);
    expect(valueOf('count > 0'), isNull);
    expect(valueOf('kDebugMode'), isNull);
    expect(valueOf('1 < other'), isNull);
  });

  test('does not compare literals of different kinds as ordered', () {
    expect(valueOf("1 < 'a'"), isNull);
  });
}
