import 'package:analyzer/dart/ast/ast.dart';

/// The boolean value [expression] always has, or `null` when it is not a
/// syntactically constant boolean.
///
/// Handles boolean literals, `!`, `&&`, `||` over constant operands, and
/// comparisons between two literals of the same kind.
///
/// Only literals written in place are folded. A `const` variable is deliberately
/// not resolved: `assert(kDebugMode)` and `if (kReleaseMode)` are constant to the
/// compiler but meaningful to the reader, and reporting them as "always the same"
/// would be wrong in spirit even where it is true in fact.
bool? constantBoolValueOf(Expression expression) {
  final node = expression.unParenthesized;

  if (node is BooleanLiteral) return node.value;

  if (node is PrefixExpression && node.operator.lexeme == '!') {
    final operand = constantBoolValueOf(node.operand);

    return operand == null ? null : !operand;
  }

  if (node is BinaryExpression) return _binaryValueOf(node);

  return null;
}

bool? _binaryValueOf(BinaryExpression node) {
  final operator = node.operator.lexeme;

  if (operator == '&&' || operator == '||') {
    final left = constantBoolValueOf(node.leftOperand);
    final right = constantBoolValueOf(node.rightOperand);

    // A decisive constant on one side settles the result on its own, but only
    // when the other side cannot change it.
    if (operator == '&&') {
      if (left == false || right == false) return false;
      if (left == true && right == true) return true;

      return null;
    }
    if (left == true || right == true) return true;
    if (left == false && right == false) return false;

    return null;
  }

  return _comparisonValueOf(node, operator);
}

bool? _comparisonValueOf(BinaryExpression node, String operator) {
  final left = _literalValueOf(node.leftOperand);
  final right = _literalValueOf(node.rightOperand);
  if (left == null || right == null) return null;

  if (operator == '==') return left == right;
  if (operator == '!=') return left != right;

  if (left is! num || right is! num) return null;

  return switch (operator) {
    '<' => left < right,
    '>' => left > right,
    '<=' => left <= right,
    '>=' => left >= right,
    _ => null,
  };
}

/// Whether [expression] is built entirely from literals written in place.
///
/// Recurses through parentheses, unary operators and binary operators, so
/// `1`, `-1`, `1 + 1` and `2 > 1` all count while `count > 1` does not. As with
/// [constantBoolValueOf], `const` variables are not resolved.
bool isSyntacticConstant(Expression expression) {
  final node = expression.unParenthesized;

  if (node is Literal) return node is! StringInterpolation;
  if (node is PrefixExpression) return isSyntacticConstant(node.operand);
  if (node is BinaryExpression) {
    return isSyntacticConstant(node.leftOperand) &&
        isSyntacticConstant(node.rightOperand);
  }

  return false;
}

/// The value of [expression] when it is a literal of a comparable kind.
Object? _literalValueOf(Expression expression) => switch (expression
    .unParenthesized) {
      IntegerLiteral(:final value) => value,
      DoubleLiteral(:final value) => value,
      SimpleStringLiteral(:final value) => value,
      BooleanLiteral(:final value) => value,
      _ => null,
    };
