import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-only-rethrow',
  category: 'common',
  problemMessage: 'This catch only rethrows, so the exception travels exactly as '
      'it would without it.',
  correctionMessage: 'Remove the catch clause, or handle the exception.',
  tags: ['correctness', 'cwe', 'error-handing'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a catch clause does nothing but `rethrow`.
///
/// Catching an exception only to rethrow it leaves the exception, its stack trace
/// and the surrounding control flow exactly as they were.
///
/// Reported only for the *last* clause of a `try`. Earlier on, a rethrow-only
/// clause does real work: in
///
/// ```dart
/// try { ... } on FormatException { rethrow; } catch (e) { handle(e); }
/// ```
///
/// the first clause is what stops `handle` from seeing format errors. Removing it
/// would change which exceptions get handled.
///
/// A `finally` alongside it makes no difference — it runs either way — so those
/// are still reported.
///
/// No quick-fix is offered: whether to drop the clause or start handling the
/// exception is the author's call.
class AvoidOnlyRethrow extends AligRule {
  /// Warns when a catch clause only rethrows.
  AvoidOnlyRethrow(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addTryStatement((node) {
      final clauses = node.catchClauses;
      if (clauses.isEmpty) return;

      final last = clauses.last;
      if (!_onlyRethrows(last)) return;

      reporter.atNode(last, code);
    });
  }
}

/// Whether [clause]'s body is a single `rethrow;`.
bool _onlyRethrows(CatchClause clause) {
  final statements = clause.body.statements;
  if (statements.length != 1) return false;

  final statement = statements.single;

  return statement is ExpressionStatement &&
      statement.expression is RethrowExpression;
}
