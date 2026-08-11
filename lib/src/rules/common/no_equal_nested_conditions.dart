import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/ast_equality.dart';
import '../../common/mutation_utils.dart';

const _meta = AligRuleMeta(
  name: 'no-equal-nested-conditions',
  category: 'common',
  problemMessage: 'An enclosing if already tests this condition, so its result '
      'here is already decided.',
  correctionMessage: 'Remove the inner condition, or correct it.',
  tags: ['correctness', 'cwe', 'conditions'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when an `if` nested inside another tests the same condition.
///
/// Inside the outer `then` branch the condition is already known true, so the
/// inner test is redundant. Inside the outer `else` branch it is known false, so
/// the inner branch is dead. Both are reported.
///
/// Deliberately not reported:
/// - `else if` chains, which `no-equal-conditions` covers, so one chain does not
///   collect two lints.
/// - Conditions whose variables are written to anywhere inside the enclosing
///   branch. After `flag = check()` the inner test is meaningful again.
/// - Conditions with side effects, which need not evaluate the same way twice.
///
/// No quick-fix is offered: collapsing the two ifs, deleting the inner branch and
/// correcting the condition are all plausible intents.
class NoEqualNestedConditions extends AligRule {
  /// Warns when a nested if repeats an enclosing condition.
  NoEqualNestedConditions(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addIfStatement((node) {
      final condition = node.expression;
      if (hasSideEffects(condition)) return;

      final key = canonicalize(condition);

      for (final enclosing in _enclosingBranches(node)) {
        if (canonicalize(enclosing.statement.expression) != key) continue;
        if (isMutatedWithin(enclosing.branch, condition)) return;

        reporter.atNode(condition, code);

        return;
      }
    });
  }
}

/// An enclosing `if` together with the branch of it that contains the inner one.
class _EnclosingBranch {
  const _EnclosingBranch(this.statement, this.branch);

  final IfStatement statement;

  /// The `then` or `else` statement that [statement] reached the inner `if`
  /// through.
  final Statement branch;
}

/// Every enclosing `if` whose branch contains [node], innermost first.
///
/// An `else if` is skipped: there the inner `if` *is* the else branch rather than
/// sitting inside it, and repeated conditions in that shape belong to
/// `no-equal-conditions`.
List<_EnclosingBranch> _enclosingBranches(IfStatement node) {
  final result = <_EnclosingBranch>[];

  AstNode? child = node;
  var parent = node.parent;
  while (parent != null) {
    if (parent is IfStatement) {
      // `else if` puts an IfStatement directly in the else slot. `else { if ... }`
      // puts a Block there, which is a genuine nesting.
      final isElseIf = parent.elseStatement == child && child is IfStatement;
      if (!isElseIf) {
        final branch = parent.thenStatement == child
            ? parent.thenStatement
            : parent.elseStatement;
        if (branch != null) result.add(_EnclosingBranch(parent, branch));
      }
    }
    child = parent;
    parent = parent.parent;
  }

  return result;
}
