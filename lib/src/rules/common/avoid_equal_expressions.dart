import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/ast_equality.dart';

const _meta = AligRuleMeta(
  name: 'avoid-equal-expressions',
  category: 'common',
  problemMessage: 'Both sides of this expression are the same, so the result '
      'does not depend on them.',
  correctionMessage: 'Replace the expression with one side, or correct one of '
      'them.',
  tags: ['correctness', 'unused-code', 'cwe', 'conditions'],
  severity: DiagnosticSeverity.WARNING,
);

/// Operators for which repeating the operand makes the expression equal to that
/// operand, so the whole expression can be replaced by one side.
const _collapsibleOperators = {'&&', '||', '&', '|', '??'};

/// Operators for which repeating the operand yields a constant. The value
/// depends on the operand's type, so these are reported without a fix.
const _constantOperators = {'-', '/', '~/', '%', '^'};

/// Warns when both sides of a binary expression are the same.
///
/// Two groups are reported:
/// - `&&`, `||`, `&`, `|` and `??`, where the expression is just its own
///   operand. The quick-fix replaces the expression with that operand.
/// - `-`, `/`, `~/`, `%` and `^`, where the result is a constant regardless of
///   the operand. These get no fix, because writing the constant requires
///   knowing the operand's type.
///
/// Deliberately not reported:
/// - `+` and `*`, which are ordinary doubling and squaring.
/// - Comparison operators. `count == count` is covered by `avoid-self-compare`,
///   and reporting it here as well would put two lints on one expression.
/// - Operands with side effects. `roll() - roll()` calls two different things.
class AvoidEqualExpressions extends AligRule {
  /// Warns when a binary expression has identical operands.
  AvoidEqualExpressions(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addBinaryExpression((node) {
      if (!_isReported(node)) return;

      reporter.atNode(node, code);
    });
  }

  @override
  List<Fix> getFixes() => [_CollapseToOneSide()];
}

bool _isReported(BinaryExpression node) {
  final operator = node.operator.lexeme;
  if (!_collapsibleOperators.contains(operator) &&
      !_constantOperators.contains(operator)) {
    return false;
  }
  if (hasSideEffects(node.leftOperand) || hasSideEffects(node.rightOperand)) {
    return false;
  }

  return areEquivalent(node.leftOperand, node.rightOperand);
}

class _CollapseToOneSide extends DartFix {
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
      if (!_collapsibleOperators.contains(node.operator.lexeme)) return;

      final builder = reporter.createChangeBuilder(
        message: 'Replace with one side',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        fileBuilder.addSimpleReplacement(
          node.sourceRange,
          node.leftOperand.toSource(),
        );
      });
    });
  }
}
