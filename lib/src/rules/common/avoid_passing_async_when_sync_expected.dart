import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/flutter_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-passing-async-when-sync-expected',
  category: 'common',
  problemMessage: 'This parameter returns void, so the future this closure '
      'produces is dropped — nothing waits for it and nothing catches its '
      'errors.',
  correctionMessage: 'Do the work synchronously, or hand the future somewhere '
      'that awaits it.',
  tags: ['correctness', 'async'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when an `async` closure is passed where a synchronous one is expected.
///
/// ```dart
/// source.listen((event) async {
///   await handle(event);
/// });
/// ```
/// `listen` takes `void Function(T)`. The closure returns a future anyway — `void`
/// accepts any value — and `listen` drops it. Two consequences, both quiet: events
/// stop being handled in order, because the next one arrives while the previous
/// `await` is still pending; and a failure inside becomes an unhandled async
/// error with no relation to the code that started it.
///
/// Reported when the closure is `async` and the parameter's return type is
/// exactly `void`. A parameter typed `Future<void> Function()` or
/// `FutureOr<void> Function()` is asking to be awaited, so passing an async
/// closure there is correct and not reported.
///
/// Two exclusions, both deliberate:
///
/// - **`forEach`** is left to the built-in `avoid_function_literals_in_foreach_calls`,
///   enabled in `lib/dart_lints.yaml`, which reports any literal there. Measured;
///   see `doc/LIMITATIONS.md`.
/// - **Flutter widget constructors.** `onPressed: () async { … }` is how the
///   framework's callbacks are written, and the framework invokes them expecting
///   the handler to deal with its own errors. Reporting it would fire on most of
///   an app's event handling.
///
/// No quick-fix is offered. The repair is either to make the body synchronous —
/// which means deciding what to do about the work that needed awaiting — or to
/// change the parameter's type, which is a change to the other side of the call.
class AvoidPassingAsyncWhenSyncExpected extends AligRule {
  /// Warns when a fire-and-forget callback is handed async work.
  AvoidPassingAsyncWhenSyncExpected(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addFunctionExpression((node) {
      if (!node.body.isAsynchronous) return;

      final argument = node.parent;
      if (argument is! ArgumentList && argument is! NamedExpression) return;
      if (_isExcludedCall(node)) return;

      final parameter = _parameterFor(node);
      if (parameter is! FunctionType) return;
      if (parameter.returnType is! VoidType) return;

      reporter.atNode(node, code);
    });
  }
}

/// The type of the parameter [closure] is being passed to.
DartType? _parameterFor(FunctionExpression closure) {
  final parent = closure.parent;
  // A named argument carries the binding, not the closure inside it.
  final Expression target = parent is NamedExpression ? parent : closure;

  return target.correspondingParameter?.type;
}

/// Whether this call is one the rule deliberately stays out of.
bool _isExcludedCall(FunctionExpression closure) {
  final call = closure.thisOrAncestorOfType<InvocationExpression>();
  if (call is MethodInvocation && call.methodName.name == 'forEach') return true;

  return _isFlutterWidgetConstruction(closure);
}

/// Whether the closure is an argument to a Flutter widget's constructor, where an
/// async callback is the framework's own idiom.
bool _isFlutterWidgetConstruction(FunctionExpression closure) {
  final creation = closure.thisOrAncestorOfType<InstanceCreationExpression>();
  final type = creation?.staticType;
  if (type is! InterfaceType) return false;

  return isWidgetSubclass(type.element);
}
