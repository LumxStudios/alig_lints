import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/ast_equality.dart';

const _meta = AligRuleMeta(
  name: 'avoid-self-compare',
  category: 'common',
  problemMessage: 'Both sides of this comparison are the same, so its result is '
      'always the same.',
  correctionMessage: 'Compare against the intended value.',
  tags: ['correctness', 'cwe', 'conditions'],
  severity: DiagnosticSeverity.WARNING,
);

/// Comparison operators covered by this rule.
///
/// The remaining operators — logical, bitwise, if-null and arithmetic — belong to
/// `avoid-equal-expressions`, so that one expression never collects two lints.
const _comparisonOperators = {'==', '!=', '<', '>', '<=', '>='};

/// Warns when both sides of a comparison are the same expression.
///
/// Also covers `identical(x, x)`, which is a comparison written as a call.
///
/// Deliberately not reported:
/// - `==` and `!=` on a `double` or `num`. `x != x` is the idiomatic NaN test,
///   the one case where comparing a value to itself is meaningful.
/// - Operands with side effects, such as `roll() == roll()`, which compares two
///   separately produced values.
///
/// No quick-fix is offered: which side was meant to be something else, and what,
/// cannot be inferred.
class AvoidSelfCompare extends AligRule {
  /// Warns when a comparison has identical sides.
  AvoidSelfCompare(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addBinaryExpression((node) {
      final operator = node.operator.lexeme;
      if (!_comparisonOperators.contains(operator)) return;

      final left = node.leftOperand;
      final right = node.rightOperand;
      if (hasSideEffects(left) || hasSideEffects(right)) return;
      if (!areEquivalent(left, right)) return;

      // `x != x` and `x == x` are how NaN is detected.
      final isEqualityCheck = operator == '==' || operator == '!=';
      if (isEqualityCheck && _mayBeDouble(left.staticType)) return;

      reporter.atNode(node, code);
    });

    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'identical') return;
      if (node.realTarget != null) return;

      final arguments = node.argumentList.arguments;
      if (arguments.length != 2) return;
      if (hasSideEffects(arguments[0]) || hasSideEffects(arguments[1])) return;
      if (!areEquivalent(arguments[0], arguments[1])) return;

      reporter.atNode(node, code);
    });
  }
}

/// Whether [type] could hold a `double`, and so could be NaN.
bool _mayBeDouble(DartType? type) {
  if (type == null) return true;

  final name = type.getDisplayString();

  return name == 'double' || name == 'double?' || name == 'num' ||
      name == 'num?';
}
