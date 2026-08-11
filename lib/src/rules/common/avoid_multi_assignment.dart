import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-multi-assignment',
  category: 'common',
  problemMessage: 'This statement assigns to more than one target at once.',
  correctionMessage: 'Give each target its own assignment.',
  tags: ['correctness', 'maintainability', 'cwe', 'assignments'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when one statement assigns to several targets at once.
///
/// `a = b = 0` reads as though both get `0`, but what it really does is assign to
/// `b` and then assign *b's value* to `a`. With different types or a setter that
/// transforms the value, those are not the same thing.
///
/// Any assignment whose right-hand side is itself an assignment counts, including
/// compound forms like `maybe ??= a = 2`.
///
/// No quick-fix is offered: splitting the chain means choosing an order and a
/// place for each statement, and where the value came from matters.
class AvoidMultiAssignment extends AligRule {
  /// Warns when assignments are chained.
  AvoidMultiAssignment(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addAssignmentExpression((node) {
      // Only the outermost link is reported, so a three-target chain gives one
      // finding rather than two.
      if (node.parent is AssignmentExpression) return;
      if (node.rightHandSide.unParenthesized is! AssignmentExpression) return;

      reporter.atNode(node, code);
    });
  }
}
