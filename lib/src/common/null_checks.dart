import 'package:analyzer/dart/ast/ast.dart';

/// The value [condition] asserts is non-null, or `null` when it is not a
/// `!= null` comparison.
///
/// Recognises the comparison written either way round, so both `x != null` and
/// `null != x` yield `x`.
Expression? nonNullCheckSubjectOf(Expression condition) {
  final node = condition.unParenthesized;
  if (node is! BinaryExpression) return null;
  if (node.operator.lexeme != '!=') return null;

  final left = node.leftOperand.unParenthesized;
  final right = node.rightOperand.unParenthesized;

  if (right is NullLiteral) return left;
  if (left is NullLiteral) return right;

  return null;
}

/// [expression] with a trailing `!` removed.
Expression withoutNullAssertion(Expression expression) {
  final node = expression.unParenthesized;

  return node is PostfixExpression && node.operator.lexeme == '!'
      ? node.operand
      : node;
}
