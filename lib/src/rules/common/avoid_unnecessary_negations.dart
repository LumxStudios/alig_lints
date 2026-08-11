import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unnecessary-negations',
  category: 'common',
  problemMessage: 'This negation can be folded into the expression it negates.',
  correctionMessage: 'Write the expression without the negation.',
  tags: ['readability', 'maintainability', 'conditions'],
  severity: DiagnosticSeverity.INFO,
);

/// Warns when a `!` can be folded into the expression it negates.
///
/// Reported shapes, each an exact complement:
/// - `!!flag` is `flag`.
/// - `!(a == b)` is `a != b`, and `!(a != b)` is `a == b`. Dart defines `!=` as
///   the negation of `==`, so the swap is always sound.
/// - `!(x is T)` is `x is! T`, and back again.
///
/// Deliberately not reported:
/// - Negated relational operators. `!(ratio < 1)` is *not* `ratio >= 1`: when
///   `ratio` is NaN both comparisons are false, so the rewrite would change the
///   result.
/// - `!(a && b)`. Turning that into `!a || !b` is De Morgan's law — a different
///   expression of the same idea, not a simplification.
class AvoidUnnecessaryNegations extends AligRule {
  /// Warns when a negation can be simplified.
  AvoidUnnecessaryNegations(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addPrefixExpression((node) {
      if (_rewriteOf(node) == null) return;

      reporter.atNode(node, code);
    });
  }

  @override
  List<Fix> getFixes() => [_FoldNegation()];
}

/// The source [node] should become, or `null` when this rule does not apply.
String? _rewriteOf(PrefixExpression node) {
  if (node.operator.lexeme != '!') return null;

  final operand = node.operand.unParenthesized;

  if (operand is PrefixExpression && operand.operator.lexeme == '!') {
    return operand.operand.toSource();
  }

  if (operand is BinaryExpression) {
    final flipped = switch (operand.operator.lexeme) {
      '==' => '!=',
      '!=' => '==',
      _ => null,
    };
    if (flipped == null) return null;

    return '${operand.leftOperand.toSource()} $flipped '
        '${operand.rightOperand.toSource()}';
  }

  if (operand is IsExpression) {
    final negated = operand.notOperator == null ? 'is!' : 'is';

    return '${operand.expression.toSource()} $negated '
        '${operand.type.toSource()}';
  }

  return null;
}

class _FoldNegation extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addPrefixExpression((node) {
      if (node.sourceRange != diagnostic.sourceRange) return;

      final rewrite = _rewriteOf(node);
      if (rewrite == null) return;

      final builder = reporter.createChangeBuilder(
        message: 'Fold the negation in',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        fileBuilder.addSimpleReplacement(node.sourceRange, rewrite);
      });
    });
  }
}
