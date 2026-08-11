import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'prefer-parentheses-with-if-null',
  category: 'common',
  problemMessage: 'The if-null operator binds looser than this one, so it takes '
      'the whole expression on its right.',
  correctionMessage: 'Add parentheses to state the grouping.',
  tags: ['control-flow', 'correctness'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when the right side of `??` is an unparenthesised binary expression.
///
/// `??` binds looser than arithmetic, comparison and logical operators, so
/// `value ?? base + 1` is `value ?? (base + 1)` — not `(value ?? base) + 1`, which
/// is how many readers first parse it. Parentheses make the grouping explicit
/// without changing anything.
///
/// A chain of `??` is not reported: `first ?? second ?? 0` groups the way it
/// reads.
///
/// Only the right operand is checked. For the left one to be a binary expression
/// it would have to be nullable, and a non-nullable left operand makes the `??`
/// itself dead — which Dart reports separately.
class PreferParenthesesWithIfNull extends AligRule {
  /// Warns when `??` takes an unparenthesised binary right operand.
  PreferParenthesesWithIfNull(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addBinaryExpression((node) {
      final operand = _unparenthesisedBinaryRightOf(node);
      if (operand == null) return;

      reporter.atNode(operand, code);
    });
  }

  @override
  List<Fix> getFixes() => [_AddParentheses()];
}

/// The right operand of [node] when it is an unparenthesised binary expression
/// that `??` swallows, or `null`.
BinaryExpression? _unparenthesisedBinaryRightOf(BinaryExpression node) {
  if (node.operator.lexeme != '??') return null;

  final right = node.rightOperand;
  if (right is! BinaryExpression) return null;
  // A `??` chain groups the way it reads.
  if (right.operator.lexeme == '??') return null;

  return right;
}

class _AddParentheses extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addBinaryExpression((node) {
      final operand = _unparenthesisedBinaryRightOf(node);
      if (operand == null) return;
      if (operand.sourceRange != diagnostic.sourceRange) return;

      final builder = reporter.createChangeBuilder(
        message: 'Add parentheses',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        // States the grouping the code already has, so behaviour is unchanged.
        fileBuilder.addSimpleReplacement(
          operand.sourceRange,
          '(${operand.toSource()})',
        );
      });
    });
  }
}
