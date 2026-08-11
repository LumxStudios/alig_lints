import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/ast_equality.dart';
import '../../common/edit_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-duplicate-test-assertions',
  category: 'common',
  problemMessage: 'This assertion repeats an earlier one in the same test, so it '
      'checks nothing new.',
  correctionMessage: 'Remove the repeated assertion, or assert something else.',
  tags: ['correctness', 'cwe', 'testing'],
  severity: DiagnosticSeverity.WARNING,
);

/// Assertion helpers whose first two positional arguments are the value under
/// test and the expectation.
const _assertionNames = {'expect', 'expectLater'};

/// Packages that declare the assertion helpers this rule recognises.
const _assertionPackages = {'matcher', 'test_api', 'test', 'flutter_test'};

/// Warns when one test body asserts the same thing twice.
///
/// Two `expect` calls with the same value and matcher mean the second verifies
/// nothing — usually a copy-paste slip where the second was meant to check a
/// different value.
///
/// A differing `reason:` does not make an assertion distinct: the thing being
/// checked is the same, so the pair is still reported.
///
/// Deliberately not caught: assertions whose value expression has side effects,
/// such as `expect(increment(), 1)`. Two such calls do different work, and
/// deleting one would change what the test exercises.
///
/// Assertions are compared only against others in the same block, so two tests
/// asserting the same thing are not reported.
class AvoidDuplicateTestAssertions extends AligRule {
  /// Warns when a test repeats an assertion.
  AvoidDuplicateTestAssertions(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addBlock((node) {
      final seen = <String>{};

      for (final statement in node.statements) {
        final key = _assertionKeyOf(statement);
        if (key == null) continue;

        if (!seen.add(key)) reporter.atNode(statement, code);
      }
    });
  }

  @override
  List<Fix> getFixes() => [_RemoveDuplicateAssertion()];
}

/// A comparable key for the assertion [statement] performs, or `null` when it is
/// not a comparable assertion.
String? _assertionKeyOf(Statement statement) {
  if (statement is! ExpressionStatement) return null;

  var expression = statement.expression;
  if (expression is AwaitExpression) expression = expression.expression;
  if (expression is! MethodInvocation) return null;
  if (!_isAssertion(expression)) return null;

  final positional = expression.argumentList.arguments
      .where((argument) => argument is! NamedExpression)
      .toList();
  if (positional.length < 2) return null;

  // A value expression that does work cannot be assumed to produce the same
  // result twice, so such calls are not compared at all.
  if (hasSideEffects(positional[0])) return null;

  // `reason:` and other named arguments are messages, not part of what is being
  // checked, so they are left out of the key.
  return '${canonicalize(positional[0])}|${canonicalize(positional[1])}';
}

bool _isAssertion(MethodInvocation node) {
  if (!_assertionNames.contains(node.methodName.name)) return false;

  final uri = node.methodName.element?.library?.uri;
  if (uri == null || uri.scheme != 'package') {
    // Unresolved: the name alone is a good enough signal in test code.
    return true;
  }

  return _assertionPackages.contains(uri.pathSegments.first);
}

class _RemoveDuplicateAssertion extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addBlock((node) {
      for (final statement in node.statements) {
        if (statement.sourceRange != diagnostic.sourceRange) continue;

        final builder = reporter.createChangeBuilder(
          message: 'Remove the repeated assertion',
          priority: 80,
        );
        builder.addDartFileEdit((fileBuilder) {
          fileBuilder.addDeletion(lineRangeOf(statement, resolver));
        });
      }
    });
  }
}
