import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-cascade-after-if-null',
  category: 'common',
  problemMessage: 'It is not obvious here whether the cascade applies to the '
      'whole if-null expression or only to one side.',
  correctionMessage: 'Add parentheses to say which you mean.',
  tags: ['correctness', 'control-flow'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a cascade follows a `??` without parentheses.
///
/// In `find() ?? fallback..bump()`, the cascade applies to the result of the
/// whole `??` — not to `fallback` alone, which is how most readers first parse it.
/// The two readings do different things when the left side is non-null, so the
/// grouping deserves to be explicit.
///
/// Both groupings are checked, so the rule does not depend on remembering which
/// way Dart binds them: a cascade whose target is an unparenthesised `??`, and a
/// `??` whose operand is an unparenthesised cascade.
class AvoidCascadeAfterIfNull extends AligRule {
  /// Warns when a cascade after `??` is not parenthesised.
  AvoidCascadeAfterIfNull(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCascadeExpression((node) {
      final ifNull = _unparenthesisedIfNull(node.target);
      if (ifNull == null) return;

      reporter.atNode(node, code);
    });

    context.registry.addBinaryExpression((node) {
      if (node.operator.lexeme != '??') return;
      if (node.rightOperand is! CascadeExpression) return;

      reporter.atNode(node, code);
    });
  }

  @override
  List<Fix> getFixes() => [_AddParentheses()];
}

/// [expression] as an `??` expression that is not already parenthesised.
BinaryExpression? _unparenthesisedIfNull(Expression expression) {
  if (expression is ParenthesizedExpression) return null;
  if (expression is! BinaryExpression) return null;

  return expression.operator.lexeme == '??' ? expression : null;
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
    context.registry.addCascadeExpression((node) {
      if (node.sourceRange != diagnostic.sourceRange) return;

      final ifNull = _unparenthesisedIfNull(node.target);
      if (ifNull == null) return;

      // Parenthesising the `??` states the grouping the code already has, so the
      // fix cannot change behaviour.
      _wrap(reporter, ifNull, 'Parenthesise the if-null expression');
    });

    context.registry.addBinaryExpression((node) {
      if (node.sourceRange != diagnostic.sourceRange) return;
      if (node.operator.lexeme != '??') return;

      final cascade = node.rightOperand;
      if (cascade is! CascadeExpression) return;

      _wrap(reporter, cascade, 'Parenthesise the cascade');
    });
  }

  void _wrap(ChangeReporter reporter, Expression target, String message) {
    final builder = reporter.createChangeBuilder(message: message, priority: 80);
    builder.addDartFileEdit((fileBuilder) {
      fileBuilder.addSimpleReplacement(
        target.sourceRange,
        '(${target.toSource()})',
      );
    });
  }
}
