import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/ast_equality.dart';

const _meta = AligRuleMeta(
  name: 'avoid-passing-self-as-argument',
  category: 'common',
  problemMessage: 'This argument is the same object the method is called on.',
  correctionMessage: 'Pass a different object, or call a method that does not '
      'need one.',
  tags: ['correctness', 'cwe', 'assignments'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when an object is passed as an argument to its own method.
///
/// `numbers.addAll(numbers)` and `box.copyFrom(box)` are almost always a slip
/// where a different object was meant — and the first of those throws at
/// runtime.
///
/// Deliberately not caught: receivers with side effects, such as
/// `make().copyFrom(make())`. Those are two separate calls producing two
/// objects, so nothing is being passed to itself.
///
/// No quick-fix is offered: which of the two references is the wrong one, and
/// what should replace it, cannot be inferred.
class AvoidPassingSelfAsArgument extends AligRule {
  /// Warns when an object is passed to one of its own methods.
  AvoidPassingSelfAsArgument(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      final target = node.realTarget;
      if (target == null) return;
      if (hasSideEffects(target)) return;

      for (final argument in node.argumentList.arguments) {
        if (areEquivalent(target, argument)) reporter.atNode(argument, code);
      }
    });
  }
}
