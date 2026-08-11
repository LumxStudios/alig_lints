import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/ast_equality.dart';

const _meta = AligRuleMeta(
  name: 'no-equal-switch-expression-cases',
  category: 'common',
  problemMessage: 'Another case of this switch expression produces the same '
      'value.',
  correctionMessage: 'Combine the patterns with `||`, or remove the redundant '
      'case.',
  tags: ['control-flow', 'correctness', 'maintainability', 'cwe'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when two cases of one switch expression produce the same value.
///
/// The fix a reader wants is usually to combine the patterns — `1 || 3 => 'small'`
/// — or to delete a case that the wildcard already covers.
///
/// Cases already sharing a body through a logical-or pattern are a single case,
/// so they are not reported. Combining patterns is the remedy here, not the
/// offence.
///
/// No quick-fix is offered: combining the patterns, deleting the case, and
/// correcting a value that was meant to differ produce different code, and which
/// was intended cannot be inferred.
class NoEqualSwitchExpressionCases extends AligRule {
  /// Warns when switch expression cases produce the same value.
  NoEqualSwitchExpressionCases(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addSwitchExpression((node) {
      final seen = <String>{};

      for (final switchCase in node.cases) {
        final key = canonicalize(switchCase.expression);

        if (!seen.add(key)) reporter.atNode(switchCase.guardedPattern, code);
      }
    });
  }
}
