import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/type_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-missing-completer-stack-trace',
  category: 'common',
  problemMessage: 'Completing with an error but no stack trace loses where it '
      'came from.',
  correctionMessage: 'Pass the stack trace as the second argument — the one from '
      'the catch clause, or StackTrace.current.',
  tags: ['correctness', 'error-handing'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when `Completer.completeError` is called without a stack trace.
///
/// ```dart
/// try {
///   ...
/// } catch (error) {
///   completer.completeError(error);
/// }
/// ```
/// Whoever awaits this future gets the error with a stack trace that starts at
/// the `await`, not at the throw. The one piece of information that would say
/// where the failure happened is available right here — `catch (error,
/// stackTrace)` — and is thrown away by omitting it.
///
/// This is the async equivalent of `throw e` instead of `rethrow`: nothing
/// breaks, and every report of the failure afterwards points at the wrong place.
///
/// Reported for any single-argument `completeError` on a `Completer`.
/// `StackTrace.current` counts as a trace, so passing that is not reported even
/// though it captures the completion site rather than the throw.
///
/// No quick-fix is offered. Inside a `catch (error)` the repair is to add
/// `, stackTrace` to the clause as well as the call — two edits in different
/// places, and the second is only correct if the first is made. Elsewhere the
/// right trace may not be in scope at all.
class AvoidMissingCompleterStackTrace extends AligRule {
  /// Warns when an error completes a future with no trace.
  AvoidMissingCompleterStackTrace(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'completeError') return;
      if (node.argumentList.arguments.length != 1) return;

      final target = node.realTarget?.staticType;
      if (!implementsCompleter(target)) return;

      reporter.atNode(node, code);
    });
  }
}
