import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-nested-futures',
  category: 'common',
  problemMessage: 'A future inside a future has to be awaited twice, and one '
      'await silently yields the inner future instead of the value.',
  correctionMessage: 'Use a single Future layer.',
  tags: ['correctness', 'async'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a `Future` type contains another `Future`.
///
/// ```dart
/// Future<Future<int>> doubled() => ...;
/// ```
/// `await doubled()` gives a `Future<int>`, not an `int` — so the value the
/// caller wanted needs a second `await`, and forgetting it produces a variable
/// holding a future where a number was expected. Since `Object?` accepts both,
/// the mistake often only shows up as a `Closure`-like value in output or a type
/// error much further along.
///
/// Nesting almost always means an `async` function returned a future it should
/// have awaited, and the declared type grew a layer to match.
///
/// Reported for any `Future` whose type arguments contain another `Future` at any
/// depth, so `Future<List<Future<int>>>` counts: awaiting it yields a list whose
/// elements still have to be awaited.
///
/// A `List<Future<T>>` on its own is not reported. That is a set of pending
/// operations someone will wait on together, which is what `Future.wait` takes.
///
/// No quick-fix is offered. Collapsing the layers means finding where the inner
/// future was created and awaiting it there, which is a change to the body rather
/// than to the type.
class AvoidNestedFutures extends AligRule {
  /// Warns when a future type wraps another future.
  AvoidNestedFutures(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addNamedType((node) {
      if (!_isFuture(node)) return;

      // Only what the author wrote: a constructor call's inferred type would
      // otherwise report the same nesting a second time on the same line.
      final written = node.typeArguments?.arguments;
      if (written == null) return;
      if (!written.any((it) => _containsFuture(it, 0))) return;

      reporter.atNode(node, code);
    });
  }
}

/// Whether [type] names a `Future`, or has one somewhere inside its arguments.
bool _containsFuture(TypeAnnotation type, int depth) {
  if (depth > 4 || type is! NamedType) return false;
  if (_isFuture(type)) return true;

  final arguments = type.typeArguments?.arguments ?? const <TypeAnnotation>[];

  return arguments.any((it) => _containsFuture(it, depth + 1));
}

/// Whether [node] names `dart:async`'s `Future`.
bool _isFuture(NamedType node) {
  final type = node.type;

  return type is InterfaceType && type.isDartAsyncFuture;
}
