import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unnecessary-futures',
  category: 'common',
  problemMessage: 'Nothing here is awaited, so the Future only makes callers '
      'wait for a value that is already available.',
  correctionMessage: 'Return the value directly, without Future.',
  tags: ['maintainability', 'async'],
  severity: DiagnosticSeverity.INFO,
);

/// Warns when a declaration's return type is wrapped in a `Future` for nothing.
///
/// ```dart
/// Future<int> counted() async => 1;
/// ```
/// Every caller now needs an `await`, and every caller's caller has to be `async`
/// to provide it. The `Future` spreads outward through the code while carrying no
/// actual wait.
///
/// Reported when the body is `async`, returns a `Future<T>`, and does nothing
/// that needs waiting for — no `await`, and no `return` of a future either. That
/// second condition matters: a body that hands back a future is doing real
/// asynchronous work, because the async machinery waits for that future before
/// completing, so its declared `Future` is not unnecessary.
///
/// **Overriding methods are skipped**, and that is the case that matters: a
/// `Future<String> read() async => 'cached'` implementing an async interface is
/// how a synchronous implementation stays compatible with it. Reporting that
/// would ask the author to break the contract.
///
/// This partitions with the built-in `unnecessary_async`, which is enabled in
/// `lib/dart_lints.yaml` and reports the neighbouring shape: `async` on a
/// declaration whose return type is *not* a `Future`, where the modifier can
/// simply be deleted. Here the return type has to change too, which is why this
/// one is `info` rather than a warning.
///
/// No quick-fix is offered. Unwrapping the return type compiles at every `await`
/// — awaiting a plain value is legal — but breaks any caller using `.then` or
/// passing the result to `Future.wait`, and those callers are not visible from
/// the declaration.
class AvoidUnnecessaryFutures extends AligRule {
  /// Warns when an async declaration never waits for anything.
  AvoidUnnecessaryFutures(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addFunctionDeclaration((node) {
      final returnType = node.returnType;
      if (returnType == null) return;
      if (!_isPointless(node.functionExpression.body, returnType)) return;

      reporter.atNode(returnType, code);
    });

    context.registry.addMethodDeclaration((node) {
      final returnType = node.returnType;
      if (returnType == null) return;
      // An async signature inherited from an interface is not this method's
      // choice to make.
      if (node.declaredFragment?.element.metadata.hasOverride ?? true) return;
      if (!_isPointless(node.body, returnType)) return;

      reporter.atNode(returnType, code);
    });
  }
}

/// Whether [body] is an `async` body that returns a `Future` and never waits.
bool _isPointless(FunctionBody body, TypeAnnotation returnType) {
  if (!body.isAsynchronous || body.isGenerator) return false;

  final type = returnType.type;
  if (type is! InterfaceType || !type.isDartAsyncFuture) return false;

  final visitor = _AsyncWorkDetector();
  body.accept(visitor);

  return !visitor.found;
}

/// Looks for a reason this body needs to be asynchronous, ignoring nested
/// closures, which do their own waiting.
///
/// An `await` is the obvious one. Returning a future counts too: the async
/// machinery waits for it before completing, so the declared `Future` is carrying
/// a real wait even though no `await` is written. So does a `throw`, which an
/// async body turns into a failed future instead of a synchronous throw.
class _AsyncWorkDetector extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitAwaitExpression(AwaitExpression node) => found = true;

  @override
  void visitForStatement(ForStatement node) {
    if (node.awaitKeyword != null) found = true;
    super.visitForStatement(node);
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    if (_isFuture(node.expression?.staticType)) found = true;
    super.visitReturnStatement(node);
  }

  // Throwing from an async body produces a failed future; without the modifier
  // the same code would throw synchronously, so the Future is carrying that.
  @override
  void visitThrowExpression(ThrowExpression node) => found = true;

  @override
  void visitExpressionFunctionBody(ExpressionFunctionBody node) {
    if (_isFuture(node.expression.staticType)) found = true;
    super.visitExpressionFunctionBody(node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}
}

bool _isFuture(DartType? type) =>
    type is InterfaceType && type.isDartAsyncFuture;
