import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';

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

/// Whether a value of [type] can be null.
///
/// `Null` itself counts, because a plain `null` literal has that type and no
/// `?` suffix — the case a suffix check alone would miss.
///
/// `dynamic` does not count. Every dynamic value can be null, so saying so about
/// a particular expression conveys nothing; `avoid-dynamic` reports the
/// annotation that created the situation instead.
bool isNullableType(DartType? type) {
  if (type == null) return false;
  if (type is DynamicType || type is InvalidType || type is VoidType) {
    return false;
  }

  return type.isDartCoreNull ||
      type.nullabilitySuffix == NullabilitySuffix.question;
}
