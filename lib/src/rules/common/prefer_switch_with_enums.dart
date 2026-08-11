import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/ast_equality.dart';
import '../../common/rule_options.dart';

const _meta = AligRuleMeta(
  name: 'prefer-switch-with-enums',
  category: 'common',
  problemMessage: 'This chain dispatches on enum values, which a switch says '
      'more directly.',
  correctionMessage: 'Use a switch statement or expression.',
  tags: ['control-flow', 'readability', 'maintainability'],
  severity: DiagnosticSeverity.INFO,
);

/// How many enum comparisons a chain needs before a switch is suggested.
const _defaultThreshold = 2;

/// Suggests a switch in place of an if chain that compares one enum value.
///
/// A switch on an enum is checked for exhaustiveness by the compiler; an if chain
/// is not, so a new enum value slips silently into the final `else`.
///
/// Reported when every condition in the chain compares the *same* enum-typed
/// expression with `==`, and there are at least [_defaultThreshold] of them. A
/// chain that also tests something else, or tests two different subjects, would
/// not translate to one switch and is left alone.
///
/// Options:
/// ```yaml
/// custom_lint:
///   rules:
///     - prefer-switch-with-enums:
///         threshold: 3
/// ```
/// The catalogue marks this rule configurable without naming the option; the key
/// above is this package's own. See `doc/LIMITATIONS.md`.
///
/// No quick-fix is offered: turning a chain into a switch means moving each body
/// and deciding what becomes the default, which is more rewriting than a fix
/// should do unattended.
class PreferSwitchWithEnums extends AligRule {
  /// Suggests a switch for enum dispatch.
  PreferSwitchWithEnums(CustomLintConfigs configs)
      : threshold = RuleOptions(configs, _meta.name)
            .integer('threshold', orElse: _defaultThreshold),
        super(_meta, configs);

  /// How many enum comparisons the chain must have.
  final int threshold;

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addIfStatement((node) {
      // Only the head of a chain; the rest are reached by walking the elses.
      if (node.parent is IfStatement) return;

      final conditions = _chainConditionsOf(node);
      if (conditions.length < threshold) return;

      final subjects = <Expression>[];
      for (final condition in conditions) {
        final subject = _enumComparisonSubjectOf(condition);
        if (subject == null) return;

        subjects.add(subject);
      }

      // Every branch has to be asking about the same value.
      final first = subjects.first;
      if (!subjects.every((subject) => areEquivalent(subject, first))) return;

      reporter.atToken(node.ifKeyword, code);
    });
  }
}

/// Every condition in the chain headed by [node], in the order they are tested.
List<Expression> _chainConditionsOf(IfStatement node) {
  final conditions = <Expression>[];

  IfStatement? current = node;
  while (current != null) {
    conditions.add(current.expression);
    final elseStatement = current.elseStatement;
    current = elseStatement is IfStatement ? elseStatement : null;
  }

  return conditions;
}

/// The value being compared, when [condition] is `subject == EnumValue`.
Expression? _enumComparisonSubjectOf(Expression condition) {
  final node = condition.unParenthesized;
  if (node is! BinaryExpression) return null;
  if (node.operator.lexeme != '==') return null;

  final left = node.leftOperand;
  final right = node.rightOperand;

  if (_isEnumConstant(right) && _isEnumTyped(left)) return left;
  if (_isEnumConstant(left) && _isEnumTyped(right)) return right;

  return null;
}

/// Whether [expression] names an enum value, as in `Status.active`.
bool _isEnumConstant(Expression expression) {
  final node = expression.unParenthesized;
  final element = switch (node) {
    PrefixedIdentifier(:final prefix) => prefix.element,
    PropertyAccess(:final target) =>
      target is Identifier ? target.element : null,
    _ => null,
  };

  return element is EnumElement;
}

bool _isEnumTyped(Expression expression) {
  final type = expression.staticType;

  return type is InterfaceType && type.element is EnumElement;
}
