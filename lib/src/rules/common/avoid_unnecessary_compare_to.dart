import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unnecessary-compare-to',
  category: 'common',
  problemMessage: 'Comparing compareTo to zero is an equality check written the '
      'long way.',
  correctionMessage: 'Use == or != directly.',
  tags: ['readability', 'consistency', 'conditions'],
  severity: DiagnosticSeverity.INFO,
);

/// Types whose `compareTo` returning zero means exactly what `==` means.
///
/// The restriction is not stylistic — for other types the rewrite changes
/// behaviour:
/// - `double` and `num`: `double.nan.compareTo(double.nan)` is `0` while
///   `nan == nan` is `false`, and `(-0.0).compareTo(0.0)` is non-zero while
///   `-0.0 == 0.0` is `true`.
/// - `DateTime`: `compareTo` looks only at the instant, while `==` also requires
///   the `isUtc` flags to match.
const _safeTypes = {'String', 'int', 'BigInt', 'Duration'};

/// Suggests replacing `a.compareTo(b) == 0` with `a == b`.
///
/// Handles `== 0` and `!= 0` with the literal on either side.
///
/// Deliberately not reported:
/// - Ordering comparisons such as `a.compareTo(b) > 0`, which is what
///   `compareTo` exists for and which many `Comparable` types cannot express
///   with operators at all.
/// - Receivers whose type is not one of [_safeTypes], where the rewrite would
///   change behaviour rather than just shorten the code.
class AvoidUnnecessaryCompareTo extends AligRule {
  /// Suggests `==` in place of a `compareTo` equality check.
  AvoidUnnecessaryCompareTo(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addBinaryExpression((node) {
      if (_rewriteOf(node) == null) return;

      reporter.atNode(node, code);
    });
  }

  @override
  List<Fix> getFixes() => [_UseEqualityOperator()];
}

/// The source text `node` should be replaced with, or `null` when this rule does
/// not apply to it.
String? _rewriteOf(BinaryExpression node) {
  final operator = node.operator.lexeme;
  if (operator != '==' && operator != '!=') return null;

  final left = node.leftOperand.unParenthesized;
  final right = node.rightOperand.unParenthesized;

  final invocation = _compareToOn(left) ?? _compareToOn(right);
  if (invocation == null) return null;

  final zero = _compareToOn(left) == null ? left : right;
  if (zero is! IntegerLiteral || zero.value != 0) return null;

  final target = invocation.realTarget;
  if (target == null) return null;

  final typeName = target.staticType?.getDisplayString();
  if (typeName == null || !_safeTypes.contains(typeName)) return null;

  final other = invocation.argumentList.arguments.single;

  return '${target.toSource()} $operator ${other.toSource()}';
}

/// [expression] as a single-argument `compareTo` call, or `null`.
MethodInvocation? _compareToOn(Expression expression) {
  final node = expression.unParenthesized;
  if (node is! MethodInvocation) return null;
  if (node.methodName.name != 'compareTo') return null;
  if (node.argumentList.arguments.length != 1) return null;
  if (node.argumentList.arguments.single is NamedExpression) return null;

  return node;
}

class _UseEqualityOperator extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addBinaryExpression((node) {
      if (node.sourceRange != diagnostic.sourceRange) return;

      final rewrite = _rewriteOf(node);
      if (rewrite == null) return;

      final builder = reporter.createChangeBuilder(
        message: 'Use ${node.operator.lexeme} directly',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        fileBuilder.addSimpleReplacement(node.sourceRange, rewrite);
      });
    });
  }
}
