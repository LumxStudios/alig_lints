import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/control_flow_utils.dart';
import '../../common/flutter_utils.dart';

const _meta = AligRuleMeta(
  name: 'use-setstate-synchronously',
  category: 'flutter',
  problemMessage: 'An await happened before this, so the widget may already be '
      'gone and setState will throw.',
  correctionMessage: 'Guard it with `if (!mounted) return;` after the await.',
  tags: ['correctness', 'cwe'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when `setState` is called after an `await` with no `mounted` check.
///
/// ```dart
/// Future<void> load() async {
///   await fetch();
///   setState(() => counter++);
/// }
/// ```
/// Between the `await` and the line after it, anything can happen — the user can
/// navigate away, a parent can rebuild without this widget, the route can be
/// popped. `setState` on a disposed `State` throws, so this crashes exactly when
/// the request was slow enough for the user to leave, which is the case nobody
/// tests.
///
/// The guard is one line: `if (!mounted) return;` immediately after the await.
///
/// A `setState` inside `if (mounted) { … }` is not reported either — both spellings
/// of the check count.
///
/// **Measured:** nothing else reports this. Flutter's own
/// `use_build_context_synchronously`, enabled in `lib/dart_lints.yaml`, covers the
/// neighbouring mistake — a `BuildContext` used after an await — but `setState`
/// takes no context, so it falls outside. The measurement is in
/// `doc/LIMITATIONS.md`.
///
/// The walk follows statements in order within one body, including into `if` and
/// `try` blocks. It does not follow a `setState` into a helper method: a call one
/// level away could be reached from anywhere, and reporting it would depend on
/// which caller you had in mind.
///
/// No quick-fix is offered. Inserting the guard is only correct immediately after
/// the await that made it necessary, and where several awaits and branches are
/// involved, which one that is depends on what the method is doing.
class UseSetstateSynchronously extends AligRule {
  /// Warns when `setState` crosses an await unguarded.
  UseSetstateSynchronously(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodDeclaration((node) {
      final owner = node.parent;
      if (owner is! ClassDeclaration) return;
      if (!isStateSubclass(owner.declaredFragment?.element)) return;

      final body = node.body;
      if (!body.isAsynchronous || body is! BlockFunctionBody) return;

      final unguarded = _UnguardedSetStateFinder();
      unguarded.walk(body.block.statements, awaited: false);
      for (final call in unguarded.calls) {
        reporter.atNode(call, code);
      }
    });
  }
}

/// Walks statements in order, tracking whether an `await` has happened and
/// whether a `mounted` check has since ruled the danger out.
///
/// A statement is either compound — a block, an `if`, a loop, a `try` — in which
/// case its parts are walked so that ordering inside them is respected, or simple,
/// in which case any `setState` it contains is reported when an await preceded it.
/// Splitting on that distinction is what keeps one call from being reported twice.
class _UnguardedSetStateFinder {
  final calls = <MethodInvocation>[];

  void walk(List<Statement> statements, {required bool awaited}) {
    var sawAwait = awaited;

    for (final statement in statements) {
      // A guard that leaves the method makes everything after it safe.
      if (sawAwait && _isMountedGuardWithExit(statement)) {
        sawAwait = false;
        continue;
      }

      final compound = _walkInto(statement, awaited: sawAwait);
      if (!compound && sawAwait) _collect(statement);
      if (!sawAwait) sawAwait = _containsAwait(statement);
    }
  }

  /// Walks the parts of a compound statement, returning whether [statement] was
  /// one. A simple statement is left to the caller to collect from.
  bool _walkInto(Statement statement, {required bool awaited}) {
    switch (statement) {
      case Block(:final statements):
        walk(statements, awaited: awaited);
      case IfStatement(:final expression, :final thenStatement):
        // Inside `if (mounted)` the check has already been made.
        final guarded = _isMountedCheck(expression, expectingNonNull: true);
        _walkOne(thenStatement, awaited: awaited && !guarded);
        _walkOne(statement.elseStatement, awaited: awaited);
      case TryStatement(:final body, :final finallyBlock):
        walk(body.statements, awaited: awaited);
        if (finallyBlock != null) walk(finallyBlock.statements, awaited: awaited);
      case ForStatement(:final body):
        _walkOne(body, awaited: awaited);
      case WhileStatement(:final body):
        _walkOne(body, awaited: awaited);
      case _:
        return false;
    }

    return true;
  }

  void _walkOne(Statement? statement, {required bool awaited}) {
    if (statement == null) return;

    walk(statement is Block ? statement.statements : [statement],
        awaited: awaited);
  }

  void _collect(Statement statement) {
    final visitor = _SetStateCollector();
    statement.accept(visitor);
    calls.addAll(visitor.calls);
  }
}

/// Whether [statement] is `if (!mounted) return;` — a check whose branch leaves.
bool _isMountedGuardWithExit(Statement statement) {
  if (statement is! IfStatement) return false;
  if (!_isMountedCheck(statement.expression, expectingNonNull: false)) {
    return false;
  }

  // `return`, `throw` and anything else that leaves all count, which is what
  // alwaysExits already decides for the whole package.
  return alwaysExits(statement.thenStatement);
}

/// Whether [condition] tests `mounted`, in the sense [expectingNonNull] asks for:
/// `mounted` itself when true, `!mounted` when false.
bool _isMountedCheck(Expression condition, {required bool expectingNonNull}) {
  final node = condition.unParenthesized;

  if (node is PrefixExpression && node.operator.lexeme == '!') {
    return !expectingNonNull && _isMountedFlag(node.operand);
  }

  return expectingNonNull && _isMountedFlag(node);
}

bool _isMountedFlag(Expression expression) {
  final node = expression.unParenthesized;
  if (node is! SimpleIdentifier || node.name != 'mounted') return false;

  return isFlutterElement(node.element, 'widgets/framework.dart');
}

bool _containsAwait(Statement statement) {
  final visitor = _AwaitDetector();
  statement.accept(visitor);

  return visitor.found;
}

class _AwaitDetector extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitAwaitExpression(AwaitExpression node) => found = true;

  @override
  void visitFunctionExpression(FunctionExpression node) {}
}

class _SetStateCollector extends RecursiveAstVisitor<void> {
  final calls = <MethodInvocation>[];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (isSetStateInvocation(node)) calls.add(node);
    node.target?.accept(this);
    node.argumentList.accept(this);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {}
}
