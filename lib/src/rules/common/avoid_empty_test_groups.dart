import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/edit_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-empty-test-groups',
  category: 'common',
  problemMessage: 'This group contains no tests, so it reports success without '
      'checking anything.',
  correctionMessage: 'Add a test, or remove the group.',
  tags: ['tests', 'correctness'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a test `group` contains no test cases.
///
/// ```dart
/// group('parsing', () {});
/// ```
/// The suite passes and the group's name appears in the output, so the report says
/// parsing was checked. It was not. A group left empty during a refactor is worse
/// than a missing one: the missing group is noticed, and this one actively claims
/// coverage that does not exist.
///
/// A group whose body has only `setUp`, `tearDown` or other scaffolding counts as
/// empty — nothing there asserts anything.
///
/// A group containing a nested group that contains tests is fine: the tests exist
/// and this group's name is part of their description.
///
/// The fix removes the group, taking its whole line range so no blank line is left
/// behind. It is offered only for a group whose body is genuinely empty of tests, so
/// nothing that runs is deleted — and if the group was a placeholder for tests still
/// to be written, the removal is what makes that visible.
class AvoidEmptyTestGroups extends AligRule {
  /// Warns when a group asserts nothing.
  AvoidEmptyTestGroups(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (!_isEmptyGroup(node)) return;

      reporter.atNode(node.methodName, code);
    });
  }

  @override
  List<Fix> getFixes() => [_RemoveGroup()];
}

/// Whether [node] is a `group(...)` call whose body holds no tests.
bool _isEmptyGroup(MethodInvocation node) {
  if (node.methodName.name != 'group') return false;
  // A method called `group` on something else is not the test function.
  if (node.realTarget != null) return false;

  final body = node.argumentList.arguments.whereType<FunctionExpression>();
  if (body.isEmpty) return false;

  final visitor = _TestCallDetector();
  for (final closure in body) {
    closure.body.accept(visitor);
  }

  return !visitor.found;
}

/// Looks for anything that actually asserts: a `test` call, or a nested `group`
/// that contains one.
class _TestCallDetector extends RecursiveAstVisitor<void> {
  bool found = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    if (name == 'test' || name == 'testWidgets') {
      found = true;
    } else if (name == 'group' && !_isEmptyGroup(node)) {
      found = true;
    }
    super.visitMethodInvocation(node);
  }
}

class _RemoveGroup extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.sourceRange != diagnostic.sourceRange) return;
      if (!_isEmptyGroup(node)) return;

      final statement = node.thisOrAncestorOfType<ExpressionStatement>();
      if (statement == null) return;

      reporter
          .createChangeBuilder(message: 'Remove the empty group', priority: 60)
          .addDartFileEdit((builder) {
        builder.addDeletion(
          lineRangeOf(statement, resolver, absorbFollowingBlankLines: true),
        );
      });
    });
  }
}
