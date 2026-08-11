import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/ast_equality.dart';

const _meta = AligRuleMeta(
  name: 'avoid-duplicate-switch-case-conditions',
  category: 'common',
  problemMessage: 'An earlier case in this switch already matches the same '
      'condition, so this case is unreachable.',
  correctionMessage: 'Remove this case, or correct its condition.',
  tags: ['correctness', 'cwe', 'conditions'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when two cases of one switch test the same condition.
///
/// Cases are matched top to bottom, so a repeated condition makes the later case
/// unreachable — usually a copy-paste slip where one of the two was meant to be
/// a different value.
///
/// Covers switch statements and switch expressions, including the legacy
/// `case <expression>:` form.
///
/// A `when` guard is part of the condition, so `case 3 when flag:` and `case 3:`
/// are two different cases and neither is reported.
///
/// No quick-fix is offered: whether the duplicate case or the one it shadows is
/// the mistake depends on which body is correct, and that is not inferable.
class AvoidDuplicateSwitchCaseConditions extends AligRule {
  /// Warns when several switch cases share a condition.
  AvoidDuplicateSwitchCaseConditions(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addSwitchStatement((node) {
      final seen = <String>{};

      for (final member in node.members) {
        switch (member) {
          case SwitchPatternCase(:final guardedPattern):
            _check(reporter, seen, guardedPattern);
          case SwitchCase(:final expression):
            if (!seen.add(canonicalize(expression))) {
              reporter.atNode(expression, code);
            }
          default:
            break;
        }
      }
    });

    context.registry.addSwitchExpression((node) {
      final seen = <String>{};

      for (final switchCase in node.cases) {
        _check(reporter, seen, switchCase.guardedPattern);
      }
    });
  }

  void _check(
    DiagnosticReporter reporter,
    Set<String> seen,
    GuardedPattern guardedPattern,
  ) {
    final guard = guardedPattern.whenClause?.expression;
    final key = '${canonicalize(guardedPattern.pattern)}'
        '|when:${guard == null ? '' : canonicalize(guard)}';

    if (!seen.add(key)) reporter.atNode(guardedPattern, code);
  }
}
