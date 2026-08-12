import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'prefer-return-await',
  category: 'common',
  problemMessage: 'Returning a future from inside a try hands it to the caller '
      'before it completes, so a failure escapes this catch.',
  correctionMessage: 'Add await so the failure happens inside the try.',
  tags: ['correctness', 'error-handing', 'async'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a future is returned from a `try` without being awaited.
///
/// ```dart
/// Future<int> load() async {
///   try {
///     return risky();
///   } catch (error) {
///     return 0;
///   }
/// }
/// ```
/// The `return` completes the moment the future is handed over, and the `try`
/// ends with it. Whatever `risky` throws afterwards arrives at the *caller*, past
/// a `catch` that was written to handle it — so the fallback never runs and the
/// error surfaces somewhere with no idea what to do with it.
///
/// `await` costs nothing here and keeps the failure inside the block.
///
/// A `finally` has the same problem in a different shape: cleanup runs while the
/// operation is still in flight, which is usually the opposite of the intent, so
/// those are reported too.
///
/// A return outside any `try` is not reported. There the future is the value, and
/// awaiting it only to return it adds a microtask — which is why the built-in
/// `unnecessary_await_in_return`, also enabled in `lib/dart_lints.yaml`, reports
/// the `await` there. The two are exact complements: inside a `try` the await is
/// required, outside it is noise.
///
/// The fix inserts `await`. It is safe in every case reported: the body is already
/// `async`, and awaiting a future in a function that returns that future changes
/// only when the failure is observed, which is the whole point.
class PreferReturnAwait extends AligRule {
  /// Warns when a returned future escapes the `try` that guards it.
  PreferReturnAwait(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addReturnStatement((node) {
      if (!_escapesAGuard(node)) return;

      reporter.atNode(node, code);
    });
  }

  @override
  List<Fix> getFixes() => [_AddAwait()];
}

/// Whether [node] returns an un-awaited future out of a `try` block.
bool _escapesAGuard(ReturnStatement node) {
  final value = node.expression;
  if (value == null || value is AwaitExpression) return false;

  final type = value.staticType;
  if (type is! InterfaceType || !type.isDartAsyncFuture) return false;

  final body = node.thisOrAncestorOfType<FunctionBody>();
  if (body == null || !body.isAsynchronous) return false;

  return _isInsideGuardedBlock(node, body);
}

/// Whether [node] sits in the `try` block of a statement that guards it, without
/// leaving [body] on the way up.
bool _isInsideGuardedBlock(AstNode node, FunctionBody body) {
  for (var current = node.parent; current != null; current = current.parent) {
    if (current == body) return false;
    // Only the try block itself: a return in the catch or finally is not being
    // guarded by this statement.
    if (current is TryStatement) return true;
    if (current is Block && current.parent is TryStatement) {
      return (current.parent! as TryStatement).body == current;
    }
  }

  return false;
}

class _AddAwait extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addReturnStatement((node) {
      if (node.sourceRange != diagnostic.sourceRange) return;

      final value = node.expression;
      if (value == null) return;

      reporter
          .createChangeBuilder(message: 'Add await', priority: 60)
          .addDartFileEdit((builder) {
        builder.addSimpleInsertion(value.offset, 'await ');
      });
    });
  }
}
