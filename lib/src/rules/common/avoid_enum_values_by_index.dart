import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-enum-values-by-index',
  category: 'common',
  problemMessage: 'Reaching an enum value by position ties this code to the '
      'order the values are declared in.',
  correctionMessage: 'Name the value, or look it up by a stable key.',
  tags: ['correctness', 'maintainability'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when an enum value is reached through `values[...]`.
///
/// Declaration order is not part of an enum's meaning, so `Status.values[0]`
/// quietly changes what it returns the day someone reorders the constants — with
/// nothing to catch it.
///
/// Reading `status.index` is left alone: that reports a position without
/// depending on one. So is iterating `values`, which does not care about order.
///
/// No quick-fix is offered: the right replacement is the name of the value that
/// was meant, which only the author knows.
class AvoidEnumValuesByIndex extends AligRule {
  /// Warns when an enum value is reached by index.
  AvoidEnumValuesByIndex(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addIndexExpression((node) {
      if (!_isEnumValuesList(node.realTarget)) return;

      reporter.atNode(node, code);
    });
  }
}

/// Whether [expression] is an enum's `values` list.
bool _isEnumValuesList(Expression expression) {
  final node = expression.unParenthesized;

  final (owner, name) = switch (node) {
    PrefixedIdentifier(:final prefix, :final identifier) => (
        prefix.element,
        identifier.name,
      ),
    PropertyAccess(:final target, :final propertyName) => (
        target is Identifier ? target.element : null,
        propertyName.name,
      ),
    _ => (null, null),
  };

  return name == 'values' && owner is EnumElement;
}
