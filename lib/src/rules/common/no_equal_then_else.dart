import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/ast_equality.dart';

const _meta = AligRuleMeta(
  name: 'no-equal-then-else',
  category: 'common',
  problemMessage: 'Both branches do the same thing, so the condition does not '
      'affect the outcome.',
  correctionMessage: 'Keep one branch, or correct the one that was meant to '
      'differ.',
  tags: ['control-flow', 'correctness', 'cwe'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when an `if` has equal then and else branches, or a conditional
/// expression has equal then and else values.
///
/// A single-statement block is unwrapped before comparing, so
/// `if (c) { f(); } else f();` is recognised as the same statement written two
/// ways.
///
/// A quick-fix that collapses to the shared branch is offered only when the
/// condition is side-effect-free. When the condition does work — `if (check())`
/// — dropping it would change behaviour, so the finding is reported for a human
/// to resolve.
class NoEqualThenElse extends AligRule {
  /// Warns when both branches of a condition are the same.
  NoEqualThenElse(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addIfStatement((node) {
      final elseStatement = node.elseStatement;
      if (elseStatement == null) return;
      // An `else if` is a chain, not a pair of equal branches.
      if (elseStatement is IfStatement) return;

      if (!areEquivalent(
        _unwrap(node.thenStatement),
        _unwrap(elseStatement),
      )) {
        return;
      }

      reporter.atNode(node, code);
    });

    context.registry.addConditionalExpression((node) {
      if (!areEquivalent(node.thenExpression, node.elseExpression)) return;

      reporter.atNode(node, code);
    });
  }

  @override
  List<Fix> getFixes() => [_KeepOneBranch()];
}

/// [statement] with a single-statement block unwrapped, so that `{ f(); }` and
/// `f();` compare equal.
AstNode _unwrap(Statement statement) {
  if (statement is Block && statement.statements.length == 1) {
    return statement.statements.single;
  }

  return statement;
}

class _KeepOneBranch extends DartFix {
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
      if (hasSideEffects(node.expression)) return;

      _replace(reporter, node.sourceRange, _unwrap(node.thenStatement));
    });

    context.registry.addConditionalExpression((node) {
      if (node.sourceRange != diagnostic.sourceRange) return;
      if (hasSideEffects(node.condition)) return;

      _replace(reporter, node.sourceRange, node.thenExpression);
    });
  }

  void _replace(ChangeReporter reporter, SourceRange range, AstNode keep) {
    final builder = reporter.createChangeBuilder(
      message: 'Keep only the shared branch',
      priority: 80,
    );
    builder.addDartFileEdit((fileBuilder) {
      fileBuilder.addSimpleReplacement(range, keep.toSource());
    });
  }
}
