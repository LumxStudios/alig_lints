import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/ast_equality.dart';

const _meta = AligRuleMeta(
  name: 'avoid-conditions-with-boolean-literals',
  category: 'common',
  problemMessage: 'A boolean literal here either fixes the result or leaves it '
      'unchanged.',
  correctionMessage: 'Remove the literal, or the whole condition.',
  tags: ['correctness', 'unused-code', 'cwe', 'conditions'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when `&&` or `||` has a boolean literal operand.
///
/// Either the literal does nothing — `flag && true` is `flag` — or it decides the
/// result on its own, making the other side dead: `flag && false` is always
/// `false`.
///
/// Comparisons against boolean literals (`flag == true`) are left to Dart's
/// built-in `no_literal_bool_comparisons`, which is enabled in
/// `lib/dart_lints.yaml`. Splitting the shapes this way covers both without
/// reimplementing the built-in or double-reporting.
///
/// The quick-fix is withheld where collapsing would drop an operand that actually
/// runs. In `check() && false` the call happens before the `false` decides the
/// result, so replacing the expression with `false` would remove it; short-circuit
/// cases like `false && check()` never evaluate the call, so collapsing them is
/// safe.
class AvoidConditionsWithBooleanLiterals extends AligRule {
  /// Warns when a boolean literal appears in a logical condition.
  AvoidConditionsWithBooleanLiterals(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addBinaryExpression((node) {
      if (_literalOperandOf(node) == null) return;

      reporter.atNode(node, code);
    });
  }

  @override
  List<Fix> getFixes() => [_CollapseCondition()];
}

/// The boolean literal operand of [node], or `null` when there is none.
BooleanLiteral? _literalOperandOf(BinaryExpression node) {
  final operator = node.operator.lexeme;
  if (operator != '&&' && operator != '||') return null;

  final left = node.leftOperand.unParenthesized;
  final right = node.rightOperand.unParenthesized;

  if (left is BooleanLiteral) return left;

  return right is BooleanLiteral ? right : null;
}

/// The source [node] collapses to, or `null` when it cannot be collapsed safely.
String? _rewriteOf(BinaryExpression node) {
  final literal = _literalOperandOf(node);
  if (literal == null) return null;

  final isAnd = node.operator.lexeme == '&&';
  final left = node.leftOperand.unParenthesized;
  final other = literal == left ? node.rightOperand : node.leftOperand;
  final literalIsOnTheRight = literal != left;

  // `x && true` / `x || false`: the literal is inert, so the other side stands.
  final literalIsInert = isAnd == literal.value;
  if (literalIsInert) return other.toSource();

  // Otherwise the literal decides the result. That is only writable when the
  // discarded side does no work — and when the literal is on the left, the other
  // side is never evaluated anyway.
  if (literalIsOnTheRight && hasSideEffects(other)) return null;

  return '${literal.value}';
}

class _CollapseCondition extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addBinaryExpression((node) {
      if (node.sourceRange != diagnostic.sourceRange) return;

      final rewrite = _rewriteOf(node);
      if (rewrite == null) return;

      final builder = reporter.createChangeBuilder(
        message: 'Collapse the condition',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        fileBuilder.addSimpleReplacement(node.sourceRange, rewrite);
      });
    });
  }
}
