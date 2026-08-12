import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unremovable-callbacks-in-listeners',
  category: 'common',
  problemMessage: 'A closure written here is a new object every time, so no later '
      'removeListener call can match it.',
  correctionMessage: 'Pass a named method or a stored function instead.',
  tags: ['memory-leak', 'correctness'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when `addListener` is given a closure that cannot be removed again.
///
/// ```dart
/// notifier.addListener(() {
///   print('changed');
/// });
/// ```
/// `removeListener` finds the listener by identity. A function literal produces a
/// fresh object each time the line runs, so there is nothing to pass back — the
/// listener stays attached for the notifier's whole life, holding whatever the
/// closure captured.
///
/// The repair is a named method: `notifier.addListener(_onChanged)`. Tearing off the
/// same method on the same object gives an equal function, so `removeListener`
/// matches it. That is why a tear-off is **not** reported and a literal is.
///
/// This is not about whether the removal exists — `always-remove-listener` asks
/// that. This rule reports the case where no correct removal is even possible.
///
/// No quick-fix is offered: extracting the closure into a method means naming it and
/// choosing where it goes, and the fix would have to add the removal too for the
/// change to be worth anything.
class AvoidUnremovableCallbacksInListeners extends AligRule {
  /// Warns when a listener is registered as an unrepeatable closure.
  AvoidUnremovableCallbacksInListeners(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'addListener') return;

      final callback = node.argumentList.arguments.singleOrNull;
      // A tear-off of the same method on the same object compares equal, so only a
      // literal is unremovable.
      if (callback is! FunctionExpression) return;

      reporter.atNode(callback, code);
    });
  }
}
