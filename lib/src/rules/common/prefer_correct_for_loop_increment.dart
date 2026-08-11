import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/ast_equality.dart';
import '../../common/mutation_utils.dart';

const _meta = AligRuleMeta(
  name: 'prefer-correct-for-loop-increment',
  category: 'common',
  problemMessage: 'This update changes nothing the condition tests, so the loop '
      'never ends.',
  correctionMessage: 'Update the variable the condition depends on.',
  tags: ['correctness', 'cwe', 'assignments'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a `for` loop updates a variable its condition does not test.
///
/// `for (var index = 0; index < limit; other++)` runs forever: the condition
/// watches `index`, and nothing ever changes it. Usually a copy-paste slip between
/// two nearby loops.
///
/// Reported only when the condition is a plain test over variables — no calls. A
/// condition like `hasMore()` depends on state the updater need not touch, so a
/// disjoint update there is perfectly normal.
///
/// Loops with no update clause are left alone: their body advances them.
///
/// No quick-fix is offered: which variable was meant is a guess, and guessing
/// wrong would turn an obvious hang into a subtle miscount.
class PreferCorrectForLoopIncrement extends AligRule {
  /// Warns when a for loop updates the wrong variable.
  PreferCorrectForLoopIncrement(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addForStatement((node) {
      final parts = node.forLoopParts;
      if (parts is! ForParts) return;

      final condition = parts.condition;
      if (condition == null) return;
      if (parts.updaters.isEmpty) return;

      // A condition that calls something can change on its own.
      if (hasSideEffects(condition)) return;

      final tested = elementsReadBy(condition);
      if (tested.isEmpty) return;

      final updated = <Element>{
        for (final updater in parts.updaters) ...elementsWrittenBy(updater),
      };
      if (updated.isEmpty) return;
      if (tested.intersection(updated).isNotEmpty) return;

      reporter.atNode(parts.updaters.first, code);
    });
  }
}
