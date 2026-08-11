import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/ast_equality.dart';
import '../../common/edit_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unnecessary-if',
  category: 'common',
  problemMessage: 'This if returns the same value as the statement after it, so '
      'the condition changes nothing.',
  correctionMessage: 'Remove the if and keep the return.',
  tags: ['control-flow', 'correctness'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when an `if` returns exactly what the statement after it returns.
///
/// ```dart
/// if (value > 0) {
///   return 0;
/// }
///
/// return 0;
/// ```
/// Both paths produce the same result, so the condition is doing no work — often
/// a sign that one of the two returns was meant to differ.
///
/// Requires the then branch to be a lone `return`. When it does other work first,
/// removing the `if` would drop that work, so those are left alone.
///
/// An `if` with an `else` is `no-equal-then-else`'s business.
///
/// The quick-fix removes the `if` only when the condition is side-effect-free;
/// with `if (check())` the finding is reported for a human, since deleting it
/// would drop the call.
class AvoidUnnecessaryIf extends AligRule {
  /// Warns when an if returns the same value as the code after it.
  AvoidUnnecessaryIf(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addIfStatement((node) {
      if (_followingReturnOf(node) == null) return;

      reporter.atNode(node, code);
    });
  }

  @override
  List<Fix> getFixes() => [_RemoveIf()];
}

/// The `return` after [node] that makes it redundant, or `null`.
ReturnStatement? _followingReturnOf(IfStatement node) {
  if (node.elseStatement != null) return null;

  final thenReturn = _loneReturnOf(node.thenStatement);
  if (thenReturn == null) return null;

  final block = node.parent;
  if (block is! Block) return null;

  final index = block.statements.indexOf(node);
  if (index < 0 || index + 1 >= block.statements.length) return null;

  final next = block.statements[index + 1];
  if (next is! ReturnStatement) return null;
  if (!areEquivalent(thenReturn.expression, next.expression)) return null;

  return next;
}

/// [statement] as a single `return`, unwrapping a one-statement block.
ReturnStatement? _loneReturnOf(Statement statement) {
  if (statement is ReturnStatement) return statement;
  if (statement is Block && statement.statements.length == 1) {
    final only = statement.statements.single;
    if (only is ReturnStatement) return only;
  }

  return null;
}

class _RemoveIf extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addIfStatement((node) {
      if (node.sourceRange != diagnostic.sourceRange) return;
      if (_followingReturnOf(node) == null) return;
      if (hasSideEffects(node.expression)) return;

      final builder = reporter.createChangeBuilder(
        message: 'Remove the if',
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
