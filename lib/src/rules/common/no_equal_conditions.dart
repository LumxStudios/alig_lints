import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/ast_equality.dart';

const _meta = AligRuleMeta(
  name: 'no-equal-conditions',
  category: 'common',
  problemMessage: 'An earlier branch of this if chain tests the same condition, '
      'so this branch can never run.',
  correctionMessage: 'Remove this branch, or correct its condition.',
  tags: ['correctness', 'unused-code', 'cwe', 'conditions'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when an `if` / `else if` chain tests the same condition twice.
///
/// Branches are tried in order, so a repeated condition makes the later branch
/// dead — usually a copy-paste slip where it was meant to test something else.
///
/// Deliberately not reported: conditions with side effects, such as two calls to
/// the same method, which may return different values each time.
///
/// No quick-fix is offered: whether the dead branch or the condition is the
/// mistake depends on which body is correct.
class NoEqualConditions extends AligRule {
  /// Warns when an if chain repeats a condition.
  NoEqualConditions(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addIfStatement((node) {
      // Only the head of a chain is analysed; the rest are reached by walking
      // the else branches from there.
      if (node.parent is IfStatement) return;

      final seen = <String>{};

      for (final condition in _conditionsOf(node)) {
        if (hasSideEffects(condition)) continue;

        if (!seen.add(canonicalize(condition))) {
          reporter.atNode(condition, code);
        }
      }
    });
  }
}

/// Every condition in the chain headed by [node], in the order they are tested.
List<Expression> _conditionsOf(IfStatement node) {
  final conditions = <Expression>[];

  IfStatement? current = node;
  while (current != null) {
    conditions.add(current.expression);
    final elseStatement = current.elseStatement;
    current = elseStatement is IfStatement ? elseStatement : null;
  }

  return conditions;
}
