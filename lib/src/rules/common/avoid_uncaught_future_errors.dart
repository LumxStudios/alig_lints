import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-uncaught-future-errors',
  category: 'common',
  problemMessage: 'This future is created inside the try but never awaited in '
      'it, so a failure arrives after the block has ended and this catch cannot '
      'see it.',
  correctionMessage: 'Await it inside the try, or attach an error handler to the '
      'future itself.',
  tags: ['correctness', 'error-handing', 'async'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a future created inside a `try` is never awaited there.
///
/// ```dart
/// try {
///   final pending = risky();
///   use(pending);
/// } catch (error) {
///   handle(error);
/// }
/// ```
/// The `try` finishes as soon as the block runs; the future completes later. When
/// it fails, the `catch` written to handle that failure is already gone, so the
/// error surfaces as an unhandled async exception with a stack trace pointing
/// nowhere useful — and the fallback the author wrote never runs.
///
/// **Measured against the analyzer first.** The built-in `unawaited_futures`,
/// enabled in `lib/dart_lints.yaml`, already reports a future used as a bare
/// statement (`risky();`) and a chained `risky().then(...)`. What it does not
/// report is a future stored in a local, which is exactly this rule's ground; the
/// measurement is in `doc/LIMITATIONS.md`.
///
/// Not reported when the future is awaited anywhere in the same `try` block —
/// including later, after other statements — or when an error handler is attached
/// to it, since `catchError` and `onError` mean the failure has somewhere to go.
///
/// The analysis is deliberately shallow: one `try` block, its own local
/// declarations, and awaits written directly in it. Following a future through a
/// field, a helper call, or another function is the whole-program analysis this
/// cannot do, and guessing would report code that handles its errors elsewhere.
///
/// No quick-fix is offered. Adding `await` at the declaration changes when the
/// surrounding code runs, which may be the reason the future was stored in the
/// first place; the alternative is an error handler whose body only the author can
/// write.
class AvoidUncaughtFutureErrors extends AligRule {
  /// Warns when a future outlives the `try` that was meant to guard it.
  AvoidUncaughtFutureErrors(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addTryStatement((node) {
      final block = node.body;
      final awaited = _AwaitedElementCollector();
      block.accept(awaited);

      for (final declaration in _futureLocalsOf(block)) {
        final element = declaration.declaredFragment?.element;
        final initializer = declaration.initializer;
        if (element == null || initializer == null) continue;
        if (awaited.elements.contains(element)) continue;
        if (_hasErrorHandler(initializer)) continue;

        reporter.atNode(initializer, code);
      }
    });
  }
}

/// The local declarations in [block] whose initializer produces a future.
List<VariableDeclaration> _futureLocalsOf(Block block) {
  final visitor = _FutureLocalCollector();
  block.accept(visitor);

  return visitor.declarations;
}

/// Whether [expression] ends in a call that gives the future somewhere to report
/// a failure.
bool _hasErrorHandler(Expression expression) {
  for (var node = expression; node is MethodInvocation;) {
    final name = node.methodName.name;
    if (name == 'catchError' || name == 'onError') return true;

    final target = node.realTarget;
    if (target == null) return false;
    node = target;
  }

  return false;
}

bool _isFuture(DartType? type) =>
    type is InterfaceType && type.isDartAsyncFuture;

class _FutureLocalCollector extends RecursiveAstVisitor<void> {
  final declarations = <VariableDeclaration>[];

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final initializer = node.initializer;
    // An awaited initializer holds the value, not the future.
    if (initializer != null &&
        initializer is! AwaitExpression &&
        _isFuture(initializer.staticType)) {
      declarations.add(node);
    }
    super.visitVariableDeclaration(node);
  }

  // A closure inside the block runs on its own schedule.
  @override
  void visitFunctionExpression(FunctionExpression node) {}
}

/// Collects the elements that are awaited somewhere in a block.
class _AwaitedElementCollector extends RecursiveAstVisitor<void> {
  final elements = <Element>{};

  @override
  void visitAwaitExpression(AwaitExpression node) {
    final awaited = node.expression;
    if (awaited is SimpleIdentifier) {
      final element = awaited.element;
      if (element != null) elements.add(element);
    }
    super.visitAwaitExpression(node);
  }
}
