import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/null_checks.dart';
import '../../common/type_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-misused-test-matchers',
  category: 'common',
  problemMessage: 'This matcher cannot describe a value of that type, so the '
      'expectation does not test what it appears to.',
  correctionMessage: 'Use a matcher that fits the value.',
  tags: ['tests', 'correctness'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when an `expect` matcher cannot apply to the value being checked.
///
/// ```dart
/// expect(items.isEmpty, isEmpty);
/// ```
/// `items.isEmpty` is a `bool`, and `isEmpty` asks a collection for its length — so
/// this fails whatever `items` holds, and the fix a reader reaches for is usually to
/// change the value rather than the matcher. `isFalse` is what was meant.
///
/// Three mismatches are reported, each one a matcher that can never pass for the
/// type it is given:
///
/// - `isEmpty` or `isNotEmpty` against something with no length — a `bool`, a number;
/// - `isTrue` or `isFalse` against a value that is not a `bool`;
/// - `isNull` or `isNotNull` against a type that cannot be null, where the answer is
///   settled before the test runs.
///
/// Only these three, and only where the type is known: the rule reports a matcher
/// that is *impossible*, not one that is merely unusual. A custom matcher, or a value
/// typed `dynamic`, is left alone — there the mismatch cannot be established, and
/// guessing would report tests that pass.
///
/// No quick-fix is offered. `expect(items.isEmpty, isEmpty)` might have meant
/// `isFalse` on the bool or `isEmpty` on the collection, and those test different
/// things.
class AvoidMisusedTestMatchers extends AligRule {
  /// Warns when a matcher cannot fit the value it checks.
  AvoidMisusedTestMatchers(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name != 'expect') return;
      if (node.realTarget != null) return;

      final arguments = node.argumentList.arguments;
      if (arguments.length < 2) return;

      final matcher = _matcherNameOf(arguments[1]);
      if (matcher == null) return;
      if (!_isImpossible(matcher, arguments.first.staticType)) return;

      reporter.atNode(arguments[1], code);
    });
  }
}

/// The name of the matcher in [argument], when it is one of the plain named ones.
String? _matcherNameOf(Expression argument) {
  final node = argument.unParenthesized;

  return node is SimpleIdentifier ? node.name : null;
}

/// Whether [matcher] can never describe a value of [type].
bool _isImpossible(String matcher, DartType? type) {
  // Nothing is known about dynamic, and an unresolved type says less.
  if (type == null || type is DynamicType || type is InvalidType) return false;

  return switch (matcher) {
    'isEmpty' || 'isNotEmpty' => !_hasLength(type),
    'isTrue' || 'isFalse' => !_isBool(type),
    'isNull' || 'isNotNull' => !isNullableType(type),
    _ => false,
  };
}

/// Whether a value of [type] has something for `isEmpty` to measure.
bool _hasLength(DartType type) {
  if (type is! InterfaceType) return false;
  if (iterableElementTypeOf(type) != null) return true;

  for (final candidate in [type, ...type.allSupertypes]) {
    if (candidate.isDartCoreString || candidate.isDartCoreMap) return true;
    // Anything that exposes a length can be asked whether it is empty.
    for (final getter in candidate.element.getters) {
      if (getter.name == 'length') return true;
    }
  }

  return false;
}

bool _isBool(DartType type) => type is InterfaceType && type.isDartCoreBool;
