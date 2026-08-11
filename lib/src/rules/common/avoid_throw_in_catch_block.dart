import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-throw-in-catch-block',
  category: 'common',
  problemMessage: 'Throwing the caught exception again restarts its stack trace '
      'from here.',
  correctionMessage: 'Use rethrow, which keeps the original trace.',
  tags: ['correctness', 'error-handing'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a catch block throws the exception it caught.
///
/// `throw e` inside `catch (e)` produces the same exception with a stack trace
/// that starts at the `throw`, hiding where the failure actually came from.
/// `rethrow` keeps the original.
///
/// Throwing a *different* exception is left alone. `throw WrappedError(e)` is a
/// deliberate choice to present a different failure to the caller, and DCM's
/// broader wording — "a throw expression inside a catch block" — would flag that
/// too. See `doc/LIMITATIONS.md`.
class AvoidThrowInCatchBlock extends AligRule {
  /// Warns when a catch block rethrows by throwing.
  AvoidThrowInCatchBlock(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addThrowExpression((node) {
      if (!_throwsCaughtException(node)) return;

      reporter.atNode(node, code);
    });
  }

  @override
  List<Fix> getFixes() => [_UseRethrow()];
}

/// Whether [node] throws the exception bound by an enclosing catch clause.
bool _throwsCaughtException(ThrowExpression node) {
  final thrown = node.expression.unParenthesized;
  if (thrown is! SimpleIdentifier) return false;

  final clause = node.thisOrAncestorOfType<CatchClause>();
  final parameter = clause?.exceptionParameter;
  if (parameter == null) return false;

  return thrown.name == parameter.name.lexeme;
}

class _UseRethrow extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addThrowExpression((node) {
      if (node.sourceRange != diagnostic.sourceRange) return;
      if (!_throwsCaughtException(node)) return;

      final builder = reporter.createChangeBuilder(
        message: 'Use rethrow',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        fileBuilder.addSimpleReplacement(node.sourceRange, 'rethrow');
      });
    });
  }
}
