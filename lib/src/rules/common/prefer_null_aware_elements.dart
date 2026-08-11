import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/ast_equality.dart';

const _meta = AligRuleMeta(
  name: 'prefer-null-aware-elements',
  category: 'common',
  problemMessage: 'Including an element only when it is non-null is what the '
      'null-aware element says directly.',
  correctionMessage: 'Use ?element.',
  tags: ['readability', 'collections', 'nullability'],
  severity: DiagnosticSeverity.INFO,
);

/// Suggests `?element` in place of an `if (x != null)` guard inside a collection.
///
/// `[if (value != null) value]` is `[?value]`, and the same holds for sets and
/// for a map entry's value. A trailing `!` on the element makes no difference —
/// `[if (value != null) value!]` is the same thing written more anxiously.
///
/// Left alone:
/// - guards with an `else`, which `?element` cannot express;
/// - guards whose element is something other than the value being tested;
/// - conditions that are not null checks.
///
/// Options: the catalogue marks this rule configurable without naming the option,
/// so none is implemented. The rule needs no configuration to work.
class PreferNullAwareElements extends AligRule {
  /// Suggests `?element` for null-guarded collection elements.
  PreferNullAwareElements(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addIfElement((node) {
      if (node.elseElement != null) return;

      final tested = _nonNullCheckSubjectOf(node.expression);
      if (tested == null) return;

      final element = _valueElementOf(node.thenElement);
      if (element == null) return;
      if (!areEquivalent(_withoutBang(element), tested)) return;

      reporter.atNode(node, code);
    });
  }
}

/// The value `condition` asserts is non-null, or `null`.
Expression? _nonNullCheckSubjectOf(Expression condition) {
  final node = condition.unParenthesized;
  if (node is! BinaryExpression) return null;
  if (node.operator.lexeme != '!=') return null;

  final left = node.leftOperand.unParenthesized;
  final right = node.rightOperand.unParenthesized;

  if (right is NullLiteral) return left;
  if (left is NullLiteral) return right;

  return null;
}

/// The expression an element contributes, for a plain element or a map entry.
Expression? _valueElementOf(CollectionElement element) => switch (element) {
      MapLiteralEntry(:final value) => value,
      Expression() => element,
      _ => null,
    };

/// [expression] with a trailing `!` removed.
Expression _withoutBang(Expression expression) {
  final node = expression.unParenthesized;

  return node is PostfixExpression && node.operator.lexeme == '!'
      ? node.operand
      : node;
}
