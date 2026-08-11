import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/ast_equality.dart';
import '../../common/edit_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unnecessary-statements',
  category: 'common',
  problemMessage: 'This statement evaluates a value and discards it, so it has '
      'no effect.',
  correctionMessage: 'Remove the statement, or use its value.',
  tags: ['correctness', 'control-flow', 'unused-code'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a statement computes something and throws it away.
///
/// `count;`, `box.value;`, `count + 1;` and `box is Box;` all evaluate to a value
/// nothing receives. Usually a half-finished edit — an intended assignment or
/// call that lost its other half.
///
/// A statement is left alone as soon as it could do work: invocations, object
/// creation, assignments, `await`, `throw`, cascades and increments all count as
/// doing something.
///
/// Dart ships an equivalent built-in lint, `unnecessary_statements`. It is
/// switched off in `lib/dart_lints.yaml` so a statement collects one warning
/// rather than two; flip that line if you would rather use the built-in.
class AvoidUnnecessaryStatements extends AligRule {
  /// Warns when a statement has no effect.
  AvoidUnnecessaryStatements(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addExpressionStatement((node) {
      if (!_hasNoEffect(node)) return;

      reporter.atNode(node, code);
    });
  }

  @override
  List<Fix> getFixes() => [_RemoveStatement()];
}

bool _hasNoEffect(ExpressionStatement node) {
  // An expression-bodied function is a single expression statement whose value
  // *is* the result, so it is never pointless.
  if (node.parent is ExpressionFunctionBody) return false;

  return !hasSideEffects(node.expression);
}

class _RemoveStatement extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addExpressionStatement((node) {
      if (node.sourceRange != diagnostic.sourceRange) return;
      if (!_hasNoEffect(node)) return;

      final builder = reporter.createChangeBuilder(
        message: 'Remove the statement',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        fileBuilder.addDeletion(
          lineRangeOf(node, resolver, absorbFollowingBlankLines: true),
        );
      });
    });
  }
}
