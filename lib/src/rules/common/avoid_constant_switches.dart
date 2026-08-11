import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/constant_conditions.dart';

const _meta = AligRuleMeta(
  name: 'avoid-constant-switches',
  category: 'common',
  problemMessage: 'This switch is on a constant, so the same branch is taken '
      'every time.',
  correctionMessage: 'Switch on a value that can vary, or keep only the branch '
      'that runs.',
  tags: ['correctness', 'conditions', 'unused-code'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a switch statement or expression is on a constant.
///
/// Every branch but one is unreachable, so the switch is either a leftover from
/// debugging or a placeholder that was never wired to a real value.
///
/// Constants are recognised syntactically — literals and operators over them, so
/// `switch (1)` and `switch (1 + 1)` both count. A `const` variable is not
/// resolved, matching the rest of the constant-folding rules: switching on a named
/// constant usually reads as deliberate configuration.
///
/// No quick-fix is offered: keeping only the reachable branch means deciding which
/// one that is and what to do with the rest, which is the author's call.
class AvoidConstantSwitches extends AligRule {
  /// Warns when a switch subject is constant.
  AvoidConstantSwitches(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addSwitchStatement((node) {
      if (!isSyntacticConstant(node.expression)) return;

      reporter.atNode(node.expression, code);
    });

    context.registry.addSwitchExpression((node) {
      if (!isSyntacticConstant(node.expression)) return;

      reporter.atNode(node.expression, code);
    });
  }
}
