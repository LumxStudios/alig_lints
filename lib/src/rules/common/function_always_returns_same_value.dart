import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/ast_equality.dart';
import '../../common/constant_conditions.dart';

const _meta = AligRuleMeta(
  name: 'function-always-returns-same-value',
  category: 'common',
  problemMessage: 'Every branch returns the same constant, so the conditions here '
      'decide nothing.',
  correctionMessage: 'Return different values, or drop the branching.',
  tags: ['control-flow', 'correctness', 'cwe'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a function branches but every branch returns the same constant.
///
/// ```dart
/// bool isValid(String input) {
///   if (input.isEmpty) return true;
///   if (input.length > 10) return true;
///   return true;
/// }
/// ```
/// The conditions look like they decide something and do not — usually a check
/// whose result was never wired up.
///
/// At least two returns are required. A function with a single constant return is
/// a deliberate constant — `int zero() => 0;` — not a mistake.
///
/// Repeated `null` returns are `function-always-returns-null`'s, so one function
/// never collects both lints.
///
/// No quick-fix is offered: the repair is to work out what each branch should
/// return, which is the author's.
class FunctionAlwaysReturnsSameValue extends AligRule {
  /// Warns when every branch returns one constant.
  FunctionAlwaysReturnsSameValue(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addFunctionDeclaration((node) {
      _check(reporter, node.name, node.functionExpression.body);
    });

    context.registry.addMethodDeclaration(
      (node) => _check(reporter, node.name, node.body),
    );
  }

  void _check(DiagnosticReporter reporter, Token name, FunctionBody body) {
    if (body.isGenerator) return;

    final visitor = _ReturnCollector();
    body.accept(visitor);

    final values = [
      for (final statement in visitor.returns) statement.expression,
    ];
    // One return is a constant by design; none means nothing to compare.
    if (values.length < 2) return;
    if (values.any((value) => value == null)) return;

    final first = values.first!;
    if (!isSyntacticConstant(first)) return;
    // Repeated nulls are the sibling rule's.
    if (first.unParenthesized is NullLiteral) return;

    if (!values.every((value) => areEquivalent(value, first))) return;

    reporter.atToken(name, code);
  }
}

/// Collects the returns belonging to one function body, not to closures inside it.
class _ReturnCollector extends RecursiveAstVisitor<void> {
  final returns = <ReturnStatement>[];

  @override
  void visitReturnStatement(ReturnStatement node) {
    returns.add(node);
    super.visitReturnStatement(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // A closure's returns are its own.
  }
}
