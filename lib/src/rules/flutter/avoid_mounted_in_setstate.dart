import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/flutter_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-mounted-in-setstate',
  category: 'flutter',
  problemMessage: 'By the time this callback runs, setState has already decided '
      'to rebuild, so checking mounted here is too late to prevent anything.',
  correctionMessage: 'Check mounted before calling setState.',
  tags: ['correctness', 'cwe'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when `mounted` is checked inside a `setState` callback.
///
/// ```dart
/// setState(() {
///   if (!mounted) return;
///   counter++;
/// });
/// ```
/// The check is in the wrong place. `setState` itself is what throws when the
/// State is gone — it asserts before running the callback — so if the widget has
/// been disposed the exception has already happened by the time this line is
/// reached. The guard reads like protection and provides none.
///
/// The check belongs one level out:
///
/// ```dart
/// if (!mounted) return;
/// setState(() => counter++);
/// ```
///
/// Reported for any reference to `mounted` inside a closure passed to `setState`,
/// whether it is used as a condition, negated, or combined with something else.
///
/// No quick-fix is offered. Moving the guard out means deciding what the early
/// return should skip — often more than the `setState` call itself — and hoisting
/// only the check would change which statements run.
class AvoidMountedInSetstate extends AligRule {
  /// Warns when a `mounted` check sits inside a `setState` callback.
  AvoidMountedInSetstate(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (!isSetStateInvocation(node)) return;

      final callback = node.argumentList.arguments.singleOrNull;
      if (callback is! FunctionExpression) return;

      final visitor = _MountedCollector();
      callback.body.accept(visitor);
      for (final reference in visitor.references) {
        reporter.atNode(reference, code);
      }
    });
  }
}

/// Collects references to `mounted` within a callback body.
class _MountedCollector extends RecursiveAstVisitor<void> {
  final references = <SimpleIdentifier>[];

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (node.name != 'mounted') return;
    // Only the framework's own flag; a field of the same name is not this.
    if (!isFlutterElement(node.element, 'widgets/framework.dart')) return;

    references.add(node);
  }
}
