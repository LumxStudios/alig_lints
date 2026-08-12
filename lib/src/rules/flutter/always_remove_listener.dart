import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'always-remove-listener',
  category: 'flutter',
  problemMessage: 'This listener is added but nothing in the class removes it, so '
      'it stays attached after the object is finished with.',
  correctionMessage: 'Call removeListener in dispose.',
  tags: ['memory-leak', 'correctness'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when `addListener` has no matching `removeListener` in the same class.
///
/// ```dart
/// @override
/// void initState() {
///   super.initState();
///   _notifier.addListener(_onChanged);
/// }
/// // no dispose, so the listener is never detached
/// ```
/// A notifier keeps a reference to every listener it holds. While the listener is
/// attached, the object that registered it stays reachable — a `State` that has
/// already been disposed, still being called back, still holding its widget and
/// everything below it. If the notifier belongs to a parent or a singleton, that
/// leak lasts as long as the app.
///
/// The check is per class: an `addListener` anywhere in it needs a `removeListener`
/// somewhere in it. That is deliberately loose about *where* — a class that removes
/// its listener in `deactivate` rather than `dispose`, or in a helper, is not
/// reported.
///
/// **Measured:** the analyzer's `cancel_subscriptions` covers the same shape for
/// stream subscriptions held in fields, and nothing covers listeners; see
/// `doc/LIMITATIONS.md`.
///
/// `avoid-unremovable-callbacks-in-listeners` asks the neighbouring question: whether
/// a removal is even possible for the callback that was passed. This one asks
/// whether it happens.
///
/// No quick-fix is offered. The removal belongs in a `dispose` that may not exist
/// yet, and the object to remove it from is not always the one in the `addListener`
/// call.
class AlwaysRemoveListener extends AligRule {
  /// Warns when a class adds a listener and never removes one.
  AlwaysRemoveListener(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      final visitor = _ListenerCallCollector();
      node.accept(visitor);

      if (visitor.additions.isEmpty || visitor.removesAny) return;

      for (final call in visitor.additions) {
        reporter.atNode(call, code);
      }
    });
  }
}

class _ListenerCallCollector extends RecursiveAstVisitor<void> {
  final additions = <MethodInvocation>[];
  bool removesAny = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    switch (node.methodName.name) {
      case 'addListener':
        additions.add(node);
      case 'removeListener':
        removesAny = true;
    }
    super.visitMethodInvocation(node);
  }
}
