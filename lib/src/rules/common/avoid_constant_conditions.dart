import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/ast_equality.dart';
import '../../common/constant_conditions.dart';

const _meta = AligRuleMeta(
  name: 'avoid-constant-conditions',
  category: 'common',
  problemMessage: 'Both sides of this comparison are constants, so its result is '
      'decided at compile time.',
  correctionMessage: 'Compare something that can vary, or use the result '
      'directly.',
  tags: ['correctness', 'conditions', 'unused-code'],
  severity: DiagnosticSeverity.WARNING,
);

/// Comparison operators whose constant operands make the result fixed.
const _comparisonOperators = {'==', '!=', '<', '>', '<=', '>='};

/// Warns when both sides of a comparison are constants.
///
/// `if (1 < 2)` and `final flag = 10 >= 20` have their answer before the program
/// runs, so the code around them is either always or never taken.
///
/// Three neighbouring shapes belong to other rules, so one expression never
/// collects two lints:
/// - equal sides — `1 == 1` — are `avoid-self-compare`'s;
/// - `&&` and `||` holding a boolean literal are
///   `avoid-conditions-with-boolean-literals`';
/// - constant conditions inside an `assert` are
///   `avoid-constant-assert-conditions`'.
///
/// No quick-fix is offered: whether the comparison should use a real value or the
/// surrounding branch should go depends on what was meant.
class AvoidConstantConditions extends AligRule {
  /// Warns when a comparison has two constant sides.
  AvoidConstantConditions(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addBinaryExpression((node) {
      if (!_comparisonOperators.contains(node.operator.lexeme)) return;
      if (constantBoolValueOf(node) == null) return;

      // `1 == 1` is a self-comparison, reported by avoid-self-compare.
      if (areEquivalent(node.leftOperand, node.rightOperand)) return;

      // Constant assert conditions have their own rule.
      if (_isInsideAssert(node)) return;

      reporter.atNode(node, code);
    });
  }
}

bool _isInsideAssert(AstNode node) =>
    node.thisOrAncestorMatching(
      (ancestor) => ancestor is AssertStatement || ancestor is AssertInitializer,
    ) !=
    null;
