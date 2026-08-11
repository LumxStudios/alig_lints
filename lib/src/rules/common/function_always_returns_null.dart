import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'function-always-returns-null',
  category: 'common',
  problemMessage: 'Every return here is null, so the nullable type promises a '
      'value that never arrives.',
  correctionMessage: 'Return a value on some path, or make the function return '
      'void.',
  tags: ['control-flow', 'correctness', 'cwe'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a function with a nullable return type only ever returns `null`.
///
/// Callers of a `String?` write null checks for a value that can never be
/// anything else — usually a stub that was never filled in, or a function that
/// should have been `void`.
///
/// Deliberately not reported:
/// - Overrides. The signature comes from the supertype, so the nullable type is
///   not this author's to change.
/// - Functions that merely fall off the end without returning. Dart's own
///   `body_might_complete_normally_nullable` covers that, and reporting it here
///   as well would put two warnings on one function.
/// - Generators, whose `return` does not produce the function's value.
class FunctionAlwaysReturnsNull extends AligRule {
  /// Warns when a nullable function only returns null.
  FunctionAlwaysReturnsNull(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addFunctionDeclaration((node) {
      _check(reporter, node.returnType, node.functionExpression.body);
    });

    context.registry.addMethodDeclaration((node) {
      if (node.metadata.any((a) => a.name.name == 'override')) return;

      _check(reporter, node.returnType, node.body);
    });
  }

  void _check(
    DiagnosticReporter reporter,
    TypeAnnotation? returnType,
    FunctionBody body,
  ) {
    if (returnType == null || !_isNullable(returnType)) return;
    if (body.isGenerator) return;
    if (body is EmptyFunctionBody) return;

    if (!_onlyReturnsNull(body)) return;

    reporter.atNode(returnType, code);
  }
}

/// Whether [type] is written with a trailing `?`, directly or inside a `Future`.
bool _isNullable(TypeAnnotation type) {
  if (type.question != null) return true;

  // `Future<String?>` is the async spelling of a nullable return.
  if (type is NamedType && type.name.lexeme == 'Future') {
    final arguments = type.typeArguments?.arguments;
    if (arguments != null && arguments.length == 1) {
      return _isNullable(arguments.single);
    }
  }

  return false;
}

/// Whether [body] has at least one `return` and every one of them returns `null`.
bool _onlyReturnsNull(FunctionBody body) {
  if (body is ExpressionFunctionBody) return _isNullLiteral(body.expression);

  final visitor = _ReturnCollector();
  body.accept(visitor);
  if (visitor.returns.isEmpty) return false;

  return visitor.returns.every(
    (statement) =>
        statement.expression != null && _isNullLiteral(statement.expression!),
  );
}

bool _isNullLiteral(Expression expression) =>
    expression.unParenthesized is NullLiteral;

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
