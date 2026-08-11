import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'prefer-simpler-boolean-expressions',
  category: 'common',
  problemMessage: 'A conditional with a boolean literal branch is a logical '
      'operator written the long way.',
  correctionMessage: 'Use && or ||, negating the condition where the literal is '
      'on the other side.',
  tags: ['readability', 'maintainability', 'conditions'],
  severity: DiagnosticSeverity.INFO,
);

/// Suggests replacing a conditional that has one boolean literal branch with a
/// logical operator.
///
/// | written | means |
/// |---|---|
/// | `c ? true : x` | `c \|\| x` |
/// | `c ? x : false` | `c && x` |
/// | `c ? false : x` | `!c && x` |
/// | `c ? x : true` | `!c \|\| x` |
///
/// Each rewrite evaluates exactly what the conditional did, in the same order:
/// the operand that the conditional skipped is the one the operator
/// short-circuits past.
///
/// Conditionals with a literal on *both* sides are
/// `avoid-unnecessary-conditionals`', so one expression never collects two lints.
///
/// No quick-fix is offered: the negated forms need the condition parenthesised
/// depending on its shape, and the message says which operator to reach for.
class PreferSimplerBooleanExpressions extends AligRule {
  /// Suggests a logical operator in place of a conditional.
  PreferSimplerBooleanExpressions(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addConditionalExpression((node) {
      final then = _booleanLiteralValueOf(node.thenExpression);
      final otherwise = _booleanLiteralValueOf(node.elseExpression);

      // Exactly one branch must be a boolean literal: none means there is
      // nothing to fold, both is the other rule's shape.
      if ((then == null) == (otherwise == null)) return;

      reporter.atNode(node, code);
    });
  }
}

/// The value of [expression] when it is a boolean literal.
bool? _booleanLiteralValueOf(Expression expression) {
  final node = expression.unParenthesized;

  return node is BooleanLiteral ? node.value : null;
}
