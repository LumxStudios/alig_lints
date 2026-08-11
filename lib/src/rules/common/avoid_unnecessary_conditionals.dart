import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unnecessary-conditionals',
  category: 'common',
  problemMessage: 'This conditional just restates its condition as a boolean.',
  correctionMessage: 'Use the condition itself, or its negation.',
  tags: ['control-flow', 'consistency', 'readability', 'conditions'],
  severity: DiagnosticSeverity.INFO,
);

/// Warns when a conditional expression only converts its condition to a boolean.
///
/// `value > 0 ? true : false` is `value > 0`, and `value > 0 ? false : true` is
/// `!(value > 0)`. The rewrite parenthesises the condition when negating it
/// would otherwise change what the `!` applies to.
///
/// Two neighbouring shapes belong to other rules, so that one expression never
/// collects two lints:
/// - `c ? x : x`, where both branches match, is `no-equal-then-else`.
/// - `c ? true : x` and `c ? x : false`, which collapse to `||` and `&&`, are
///   `prefer-simpler-boolean-expressions`.
class AvoidUnnecessaryConditionals extends AligRule {
  /// Warns when a conditional only restates its condition.
  AvoidUnnecessaryConditionals(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addConditionalExpression((node) {
      if (_rewriteOf(node) == null) return;

      reporter.atNode(node, code);
    });
  }

  @override
  List<Fix> getFixes() => [_UseConditionDirectly()];
}

/// The source text [node] should become, or `null` when this rule does not apply.
String? _rewriteOf(ConditionalExpression node) {
  final then = _booleanValueOf(node.thenExpression);
  final otherwise = _booleanValueOf(node.elseExpression);
  if (then == null || otherwise == null) return null;
  // `c ? true : true` and `c ? false : false` are no-equal-then-else's business.
  if (then == otherwise) return null;

  final condition = node.condition.unParenthesized;

  if (then) return condition.toSource();

  return '!${_negatable(condition) ? condition.toSource() : '(${condition.toSource()})'}';
}

/// The boolean [expression] denotes, or `null` when it is not a boolean literal.
bool? _booleanValueOf(Expression expression) {
  final node = expression.unParenthesized;

  return node is BooleanLiteral ? node.value : null;
}

/// Whether `!` can be written directly before [expression] without changing what
/// it applies to.
bool _negatable(Expression expression) => switch (expression) {
      SimpleIdentifier() => true,
      PrefixedIdentifier() => true,
      PropertyAccess() => true,
      MethodInvocation() => true,
      IndexExpression() => true,
      FunctionExpressionInvocation() => true,
      Literal() => true,
      PrefixExpression() => true,
      _ => false,
    };

class _UseConditionDirectly extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addConditionalExpression((node) {
      if (node.sourceRange != diagnostic.sourceRange) return;

      final rewrite = _rewriteOf(node);
      if (rewrite == null) return;

      final builder = reporter.createChangeBuilder(
        message: 'Use the condition directly',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        fileBuilder.addSimpleReplacement(node.sourceRange, rewrite);
      });
    });
  }
}
