import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/ast_equality.dart';
import '../../common/null_checks.dart';

const _meta = AligRuleMeta(
  name: 'prefer-null-aware-spread',
  category: 'common',
  problemMessage: 'Spreading only when the collection is non-null is what the '
      'null-aware spread says directly.',
  correctionMessage: 'Use ...? instead.',
  tags: ['readability', 'collections', 'nullability'],
  severity: DiagnosticSeverity.INFO,
);

/// Suggests `...?` in place of an `if (x != null)` guard around a spread.
///
/// `[if (values != null) ...values]` is `[...?values]`, in lists, sets and maps
/// alike. A trailing `!` on the spread makes no difference.
///
/// Left alone: guards with an `else`, which `...?` cannot express, and guards
/// that spread something other than the value being tested.
class PreferNullAwareSpread extends AligRule {
  /// Suggests `...?` for null-guarded spreads.
  PreferNullAwareSpread(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addIfElement((node) {
      if (node.elseElement != null) return;

      final tested = nonNullCheckSubjectOf(node.expression);
      if (tested == null) return;

      final spread = node.thenElement;
      if (spread is! SpreadElement) return;
      // An already null-aware spread has nothing to gain.
      if (spread.isNullAware) return;

      if (!areEquivalent(withoutNullAssertion(spread.expression), tested)) {
        return;
      }

      reporter.atNode(node, code);
    });
  }
}
