import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/constant_conditions.dart';
import '../../common/edit_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-constant-assert-conditions',
  category: 'common',
  problemMessage: 'This assert condition is always the same, so it checks '
      'nothing.',
  correctionMessage: 'Assert something that can vary, or remove the assert.',
  tags: ['correctness', 'conditions'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when an `assert` condition is constant.
///
/// An always-true condition never fires, so the assert documents nothing an
/// unchecked comment would not. An always-false one fires every time it is
/// reached, which is a bug unless that is the point.
///
/// A bare `assert(false)` is exempt: it is the recognised way to mark a branch as
/// unreachable, and the literal `false` is the whole expression rather than a
/// condition that happens to fold. `assert(2 < 1)` is not exempt — that folds to
/// false by accident rather than by intent.
///
/// The quick-fix only removes always-true asserts. Removing an always-false one
/// would delete a throw that currently happens.
class AvoidConstantAssertConditions extends AligRule {
  /// Warns when an assert condition cannot vary.
  AvoidConstantAssertConditions(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addAssertStatement((node) {
      if (_constantValueOf(node.condition) == null) return;

      reporter.atNode(node.condition, code);
    });

    context.registry.addAssertInitializer((node) {
      if (_constantValueOf(node.condition) == null) return;

      reporter.atNode(node.condition, code);
    });
  }

  @override
  List<Fix> getFixes() => [_RemoveAssert()];
}

/// The constant value of [condition], or `null` when it is not constant or is the
/// exempt `assert(false)` idiom.
bool? _constantValueOf(Expression condition) {
  final node = condition.unParenthesized;
  if (node is BooleanLiteral && !node.value) return null;

  return constantBoolValueOf(node);
}

class _RemoveAssert extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addAssertStatement((node) {
      if (node.condition.sourceRange != diagnostic.sourceRange) return;
      if (_constantValueOf(node.condition) != true) return;

      final builder = reporter.createChangeBuilder(
        message: 'Remove the assert',
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
