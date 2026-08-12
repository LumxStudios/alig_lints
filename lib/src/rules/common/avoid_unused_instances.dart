import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/disposal.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unused-instances',
  category: 'common',
  problemMessage: 'This object is created and immediately thrown away.',
  correctionMessage: 'Use the result, or remove the line.',
  tags: ['unused-code', 'correctness'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a newly created object is discarded.
///
/// ```dart
/// void run() {
///   Thing();
/// }
/// ```
/// Almost always a line that lost its left-hand side: the assignment was deleted, or
/// the `return` was, and the construction stayed. The object is built and collected
/// with nothing having read it.
///
/// **The exception, and it is a real one:** a constructor called for what it does
/// rather than for what it returns — one that registers the instance somewhere, or
/// starts something. The rule cannot tell that apart from a mistake, so such code is
/// reported. It is a design worth a second look, but it is not a defect, and the
/// golden for this rule keeps an example of it so the false positive is not a surprise.
///
/// **Disposable types go to `avoid-undisposed-instances`**, whose message says what to
/// do about them. Reporting them here as well would put two warnings on one line.
///
/// No quick-fix is offered: deleting the line is right when the construction is inert
/// and wrong when the constructor is the point, and the rule cannot tell which.
class AvoidUnusedInstances extends AligRule {
  /// Warns when a construction's result goes nowhere.
  AvoidUnusedInstances(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addExpressionStatement((node) {
      final expression = node.expression;
      if (expression is! InstanceCreationExpression) return;
      // A disposable instance has its own rule, with a more useful message.
      if (isDisposable(expression.staticType)) return;

      reporter.atNode(expression, code);
    });
  }
}
