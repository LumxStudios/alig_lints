import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unnecessary-local-late',
  category: 'common',
  problemMessage: 'This variable is assigned on every path right after it is '
      'declared, so late has no effect.',
  correctionMessage: 'Remove the late keyword.',
  tags: ['maintainability', 'nullability', 'assignments'],
  severity: DiagnosticSeverity.INFO,
);

/// Warns when a `late` local variable is assigned on every path before use.
///
/// A `final` local does not need `late` to be assigned after its declaration:
/// Dart's definite-assignment analysis already allows that. `late` only earns its
/// place when the assignment might not happen, or when an initializer should be
/// deferred until first use.
///
/// Reported when the statement immediately after the declaration assigns the
/// variable — either directly, or through an `if`/`else` where both branches do.
///
/// Deliberately not reported:
/// - Declarations with an initializer, such as `late final value = compute()`,
///   where `late` defers the computation.
/// - Assignments on only some paths.
/// - Assignments further down the block, with other statements in between. There
///   the deferral is doing something, and the narrow check keeps this rule from
///   guessing at flow it cannot see. See `doc/LIMITATIONS.md`.
class AvoidUnnecessaryLocalLate extends AligRule {
  /// Warns when `late` on a local is redundant.
  AvoidUnnecessaryLocalLate(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addBlock((node) {
      for (var index = 0; index < node.statements.length - 1; index++) {
        final statement = node.statements[index];
        if (statement is! VariableDeclarationStatement) continue;

        final lateKeyword = statement.variables.lateKeyword;
        if (lateKeyword == null) continue;

        final variables = statement.variables.variables;
        if (variables.length != 1) continue;

        final variable = variables.single;
        if (variable.initializer != null) continue;

        final element = variable.declaredFragment?.element;
        if (element == null) continue;

        if (_assignsOnEveryPath(node.statements[index + 1], element)) {
          reporter.atToken(lateKeyword, code);
        }
      }
    });
  }

  @override
  List<Fix> getFixes() => [_RemoveLate()];
}

/// Whether [statement] assigns [target] however it runs.
bool _assignsOnEveryPath(Statement statement, Element target) =>
    switch (statement) {
      ExpressionStatement(:final expression) => _assignsTo(expression, target),
      Block(:final statements) =>
        statements.any((inner) => _assignsOnEveryPath(inner, target)),
      IfStatement(:final thenStatement, :final elseStatement) =>
        elseStatement != null &&
            _assignsOnEveryPath(thenStatement, target) &&
            _assignsOnEveryPath(elseStatement, target),
      _ => false,
    };

bool _assignsTo(Expression expression, Element target) {
  if (expression is! AssignmentExpression) return false;
  if (expression.operator.lexeme != '=') return false;

  final left = expression.leftHandSide;

  return left is SimpleIdentifier && expression.writeElement == target;
}

class _RemoveLate extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addVariableDeclarationStatement((node) {
      final lateKeyword = node.variables.lateKeyword;
      if (lateKeyword == null) return;
      if (lateKeyword.offset != diagnostic.offset) return;

      final builder = reporter.createChangeBuilder(
        message: 'Remove the late keyword',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        fileBuilder.addDeletion(
          SourceRange(
            lateKeyword.offset,
            lateKeyword.next!.offset - lateKeyword.offset,
          ),
        );
      });
    });
  }
}
