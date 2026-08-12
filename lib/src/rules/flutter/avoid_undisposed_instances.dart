import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/disposal.dart';

const _meta = AligRuleMeta(
  name: 'avoid-undisposed-instances',
  category: 'flutter',
  problemMessage: 'Nothing keeps this instance, so nothing can dispose it — and a '
      'new one is created every time this line runs.',
  correctionMessage: 'Store it in a field and dispose it in dispose.',
  tags: ['memory-leak', 'correctness'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when something disposable is created without being kept.
///
/// ```dart
/// TextField(controller: TextEditingController())
/// ```
/// Two problems at once, and the second is the one that bites. There is no handle,
/// so the controller can never be disposed; and this is inside `build`, so every
/// rebuild makes another one — each with its own listeners, each holding the text
/// the user typed into the last one. The field silently loses its content on
/// rebuild, which reads as a state-management problem rather than as a missing
/// field.
///
/// Reported when an instance of a type declaring `dispose` is created somewhere its
/// value is not kept: not assigned to anything, not returned, not stored in a
/// variable. Returning one is how a factory hands over ownership, so that is not
/// reported.
///
/// **This is a shape check, not ownership analysis.** Whether an instance is
/// eventually disposed can only be settled by following it through the program,
/// which is beyond what one file shows. What this catches is the case where the
/// question cannot even be asked, because the value was never kept — the same
/// reasoning as `avoid-unassigned-stream-subscriptions`, and the reason both are
/// worth having despite neither proving a leak.
///
/// Its sibling `dispose-fields` covers the other half: an instance that *is* kept in
/// a `State` field and still never disposed.
///
/// **Options:** the catalogue marks this rule configurable without naming the
/// option; none is implemented. It is the rule most likely to want one — a project
/// with its own disposable types held by a container would exempt them — and that is
/// recorded in `doc/LIMITATIONS.md`.
///
/// No quick-fix is offered. The repair adds a field, moves the creation to
/// `initState`, and adds the disposal — three edits in three places, and in a
/// `StatelessWidget` it means converting the widget first.
class AvoidUndisposedInstances extends AligRule {
  /// Warns when a disposable instance is created and dropped.
  AvoidUndisposedInstances(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      if (!isDisposable(node.staticType)) return;
      if (_isKept(node)) return;

      reporter.atNode(node, code);
    });
  }
}

/// Whether the value [node] produces is held on to by the code around it.
bool _isKept(InstanceCreationExpression node) {
  final parent = node.parent;

  return switch (parent) {
    // Stored under a name, so something can reach it later.
    VariableDeclaration() => true,
    AssignmentExpression() => true,
    // Handed to the caller, whose job it becomes.
    ReturnStatement() => true,
    ExpressionFunctionBody() => true,
    // A cascade that disposes it right here needs no handle.
    CascadeExpression() => true,
    _ => false,
  };
}
