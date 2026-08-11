import 'package:alig_lints/src/common/ast_equality.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:test/test.dart';

/// Parses `var _x = <source>;` and returns the initializer expression.
Expression parseExpression(String source) {
  final unit = parseString(content: 'var _x = $source;').unit;
  final declaration = unit.declarations.single as TopLevelVariableDeclaration;

  return declaration.variables.variables.single.initializer!;
}

void main() {
  test('equivalent expressions compare equal despite formatting', () {
    expect(
      areEquivalent(parseExpression('a + b'), parseExpression('a  +  b')),
      isTrue,
    );
    expect(
      areEquivalent(parseExpression('(a + b)'), parseExpression('a + b')),
      isTrue,
    );
    expect(
      areEquivalent(parseExpression('f(1, x: 2)'), parseExpression('f(1, x: 2)')),
      isTrue,
    );
  });

  test('different expressions do not compare equal', () {
    expect(
      areEquivalent(parseExpression('a + b'), parseExpression('b + a')),
      isFalse,
    );
    expect(
      areEquivalent(parseExpression('a.b'), parseExpression('a.c')),
      isFalse,
    );
    expect(
      areEquivalent(parseExpression('f(1)'), parseExpression('f(2)')),
      isFalse,
    );
  });

  test('canonicalize keys equivalent expressions identically', () {
    expect(
      canonicalize(parseExpression('a + b')),
      canonicalize(parseExpression('(a) + (b)')),
    );
    expect(
      canonicalize(parseExpression('a + b')),
      isNot(canonicalize(parseExpression('a - b'))),
    );
  });

  test('hasSideEffects detects invocations and mutations', () {
    expect(hasSideEffects(parseExpression('a + b')), isFalse);
    expect(hasSideEffects(parseExpression('a.b.c')), isFalse);
    expect(hasSideEffects(parseExpression('[1, 2]')), isFalse);
    expect(hasSideEffects(parseExpression('f()')), isTrue);
    expect(hasSideEffects(parseExpression('a++')), isTrue);
    expect(hasSideEffects(parseExpression('--a')), isTrue);
    expect(hasSideEffects(parseExpression('Foo()')), isTrue);
    expect(hasSideEffects(parseExpression('a..b()')), isTrue);
  });

  test('hasSideEffects treats rethrow as doing something', () {
    // `rethrow` only parses inside a catch, so it needs a fuller snippet.
    final unit = parseString(content: '''
void f() {
  try {
    g();
  } catch (e) {
    rethrow;
  }
}
''').unit;
    final function = unit.declarations.single as FunctionDeclaration;
    final body = function.functionExpression.body as BlockFunctionBody;
    final tryStatement = body.block.statements.single as TryStatement;
    final statement =
        tryStatement.catchClauses.single.body.statements.single
            as ExpressionStatement;

    expect(hasSideEffects(statement.expression), isTrue);
  });

  test('hasSideEffects does not treat plain negation as a mutation', () {
    expect(hasSideEffects(parseExpression('-a')), isFalse);
    expect(hasSideEffects(parseExpression('!a')), isFalse);
  });
}
