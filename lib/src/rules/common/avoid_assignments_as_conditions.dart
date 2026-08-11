import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-assignments-as-conditions',
  category: 'common',
  problemMessage: 'This condition assigns a value instead of testing one.',
  correctionMessage: 'Use == to compare, or move the assignment out of the '
      'condition.',
  tags: ['correctness', 'readability', 'cwe', 'assignments'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when an assignment appears inside a condition.
///
/// `if (flag = true)` compiles whenever the assigned value is a `bool`, and it
/// almost always means `==` was intended. The C-style
/// `if ((next = read()) != null)` idiom is reported too: it hides a state change
/// inside a test, which is what this rule is about.
///
/// Covers the conditions of `if`, `while`, `do`, `for` and conditional
/// expressions. A `for` loop's update clause is not a condition, so `index += 1`
/// there is left alone.
///
/// No quick-fix is offered: whether the assignment should become a comparison or
/// move to its own statement depends on which was meant.
class AvoidAssignmentsAsConditions extends AligRule {
  /// Warns when a condition contains an assignment.
  AvoidAssignmentsAsConditions(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    void check(Expression? condition) {
      if (condition == null) return;
      if (!_containsAssignment(condition)) return;

      reporter.atNode(condition, code);
    }

    context.registry.addIfStatement((node) => check(node.expression));
    context.registry.addWhileStatement((node) => check(node.condition));
    context.registry.addDoStatement((node) => check(node.condition));
    context.registry.addConditionalExpression((node) => check(node.condition));
    context.registry.addForStatement((node) {
      final parts = node.forLoopParts;
      if (parts is ForParts) check(parts.condition);
    });
  }
}

bool _containsAssignment(Expression condition) {
  final visitor = _AssignmentDetector();
  condition.accept(visitor);

  return visitor.found;
}

class _AssignmentDetector extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    found = true;
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // A closure in a condition runs later; assignments inside it belong to its
    // own body, not to the test.
  }
}
