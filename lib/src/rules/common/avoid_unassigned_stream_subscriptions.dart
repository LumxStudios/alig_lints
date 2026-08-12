import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unassigned-stream-subscriptions',
  category: 'common',
  problemMessage: 'Nothing keeps this subscription, so there is no way to cancel '
      'it and it outlives whatever set it up.',
  correctionMessage: 'Assign it to a field or variable and cancel it later.',
  tags: ['memory-leak', 'correctness'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when the result of `listen` is discarded.
///
/// ```dart
/// void watch(Stream<int> source) {
///   source.listen(print);
/// }
/// ```
/// The subscription is the only handle on the listener. Without it the callback
/// keeps running for as long as the stream does, holding on to whatever it closes
/// over — often the object that started listening, which then cannot be collected.
/// Nothing fails; the app just gets slower and does more work than it should, and
/// the cause is invisible at the call.
///
/// **Measured against the analyzer first.** The built-in `cancel_subscriptions`,
/// enabled in `lib/dart_lints.yaml`, reports a subscription held in a *field* that
/// is never cancelled. It says nothing about a subscription that was never kept at
/// all, which is this rule's ground and the worse case of the two. The measurement
/// is in `doc/LIMITATIONS.md`.
///
/// Only a `listen` whose result is thrown away is reported — used as a statement on
/// its own. Assigning it, returning it, or storing it in a local all count as
/// keeping it, even if the cancel never comes: that second half is what
/// `cancel_subscriptions` is for, and reporting it here too would put two warnings
/// on one line.
///
/// No quick-fix is offered. Where the handle should live — a field, a local, a list
/// of subscriptions — and where the cancel belongs are decisions about the
/// surrounding object's lifetime.
class AvoidUnassignedStreamSubscriptions extends AligRule {
  /// Warns when a subscription is created and dropped.
  AvoidUnassignedStreamSubscriptions(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addExpressionStatement((node) {
      final expression = node.expression;
      if (expression is! MethodInvocation) return;
      if (expression.methodName.name != 'listen') return;
      if (!_isSubscription(expression.staticType)) return;

      reporter.atNode(expression, code);
    });
  }
}

bool _isSubscription(DartType? type) {
  if (type is! InterfaceType) return false;

  for (final candidate in [type, ...type.allSupertypes]) {
    final element = candidate.element;
    if (element.name == 'StreamSubscription' &&
        element.library.isDartAsync) {
      return true;
    }
  }

  return false;
}
