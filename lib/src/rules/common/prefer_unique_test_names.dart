import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'prefer-unique-test-names',
  category: 'common',
  problemMessage: 'Another test in this group already has this name, so a failure '
      'report cannot say which one broke.',
  correctionMessage: 'Give the test a name that describes what it checks.',
  tags: ['tests', 'maintainability'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when two tests in the same group share a name.
///
/// ```dart
/// test('parses an empty input', () { … });
/// test('parses an empty input', () { … });
/// ```
/// A test's name is its identifier in every report, every CI log and every "which
/// test is flaky" conversation. Two tests with one name make all of those ambiguous —
/// and the usual cause is a copy-paste where the body changed and the name did not,
/// which means the name now describes only one of them.
///
/// Scoped **per group**: the same name in a different `group` describes a different
/// thing, and the group name is part of how the runner reports it. Tests directly in
/// `main` count as one group.
///
/// Only literal names are compared. A name built at run time — `test('case $i', …)`
/// in a loop — is intended to vary and cannot be compared here.
///
/// No quick-fix is offered: the second name has to say how that test differs, which is
/// the thing the duplicate is failing to say.
class PreferUniqueTestNames extends AligRule {
  /// Warns when a test name repeats inside its group.
  PreferUniqueTestNames(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    // Each closure body is one group's scope: the tests written directly in it.
    context.registry.addFunctionExpression((node) {
      final body = node.body;
      if (body is! BlockFunctionBody) return;

      final seen = <String>{};
      for (final statement in body.block.statements) {
        final name = _testNameIn(statement);
        if (name == null) continue;

        if (!seen.add(name.stringValue!)) reporter.atNode(name, code);
      }
    });
  }
}

/// The literal name of the `test` call [statement] makes, or null when it is
/// something else or the name is computed.
StringLiteral? _testNameIn(Statement statement) {
  if (statement is! ExpressionStatement) return null;

  final expression = statement.expression;
  if (expression is! MethodInvocation) return null;
  if (expression.methodName.name != 'test') return null;
  if (expression.realTarget != null) return null;

  final first = expression.argumentList.arguments.firstOrNull;
  // A computed name is meant to vary, so there is nothing to compare.
  if (first is! StringLiteral || first.stringValue == null) return null;

  return first;
}
