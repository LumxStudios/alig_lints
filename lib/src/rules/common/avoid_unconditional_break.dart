import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unconditional-break',
  category: 'common',
  problemMessage: 'This leaves the loop on the first pass, so the loop never '
      'iterates.',
  correctionMessage: 'Guard the exit with a condition, or drop the loop.',
  tags: ['control-flow', 'correctness', 'cwe'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a loop body exits unconditionally.
///
/// A `break`, `return` or `throw` sitting directly in a loop body — not inside an
/// `if` or a `switch` — means the body runs at most once. The loop is then either a
/// long way of writing "take the first element", or a guard that lost its
/// condition.
///
/// Only the loop body's own statements are examined, so a `break` inside a
/// `switch` is not mistaken for one that leaves the loop: it leaves the switch.
///
/// An unconditional `continue` is reported only when something follows it, where it
/// makes the rest of the body unreachable. A trailing one is
/// `avoid-unnecessary-continue`'s, so the two rules never both fire.
///
/// No quick-fix is offered: adding the missing condition, or replacing the loop
/// with a `first` / `firstWhere` call, are different repairs for different
/// intentions.
class AvoidUnconditionalBreak extends AligRule {
  /// Warns when a loop body exits on its first pass.
  AvoidUnconditionalBreak(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    void check(Statement body) {
      if (body is! Block) return;

      final statements = body.statements;
      for (var index = 0; index < statements.length; index++) {
        final statement = statements[index];
        final isLast = index == statements.length - 1;
        if (!_exitsUnconditionally(statement, isLast: isLast)) continue;

        reporter.atNode(statement, code);

        // One finding per loop: everything after an unconditional exit is
        // unreachable anyway, and the analyzer already says so.
        return;
      }
    }

    context.registry.addForStatement((node) => check(node.body));
    context.registry.addWhileStatement((node) => check(node.body));
    context.registry.addDoStatement((node) => check(node.body));
  }
}

/// Whether [statement] leaves the loop body without testing anything.
bool _exitsUnconditionally(Statement statement, {required bool isLast}) =>
    switch (statement) {
      BreakStatement() => true,
      ReturnStatement() => true,
      ExpressionStatement(:final expression) => expression is ThrowExpression,
      // A trailing `continue` is merely redundant; one with statements after it
      // makes them unreachable.
      ContinueStatement() => !isLast,
      _ => false,
    };
