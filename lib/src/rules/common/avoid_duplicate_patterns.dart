import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/ast_equality.dart';

const _meta = AligRuleMeta(
  name: 'avoid-duplicate-patterns',
  category: 'common',
  problemMessage: 'This pattern already appears in the same logical chain, so it '
      'matches nothing new.',
  correctionMessage: 'Remove the duplicated pattern.',
  tags: ['correctness', 'unused-code', 'cwe', 'conditions'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a `||` or `&&` pattern chain repeats one of its operands.
///
/// Logical patterns nest to the left, so `1 || 2 || 1` parses as
/// `(1 || 2) || 1`. The whole chain is flattened before comparing, which is what
/// lets a duplicate be found however far apart its occurrences are.
///
/// `||` and `&&` chains are treated separately: in `a && (b || a)` the inner `a`
/// belongs to a different chain and is not a duplicate of the outer one.
class AvoidDuplicatePatterns extends AligRule {
  /// Warns when a logical pattern chain contains duplicate patterns.
  AvoidDuplicatePatterns(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    void check(DartPattern node) {
      if (_isPartOfLargerChain(node)) return;

      final seen = <String>{};
      for (final operand in _flatten(node)) {
        if (!seen.add(canonicalize(operand))) reporter.atNode(operand, code);
      }
    }

    context.registry.addLogicalOrPattern(check);
    context.registry.addLogicalAndPattern(check);
  }

  @override
  List<Fix> getFixes() => [_RemoveDuplicatePattern()];
}

/// Whether [node] is an operand of an enclosing chain using the same operator,
/// in which case that outer chain is the one to analyse.
bool _isPartOfLargerChain(DartPattern node) {
  final parent = node.parent;

  return switch (node) {
    LogicalOrPattern() => parent is LogicalOrPattern,
    LogicalAndPattern() => parent is LogicalAndPattern,
    _ => false,
  };
}

/// The operands of the chain rooted at [node], left to right.
List<DartPattern> _flatten(DartPattern node) => switch (node) {
      LogicalOrPattern(:final leftOperand, :final rightOperand) => [
          ..._flattenSameOperator(leftOperand, isOr: true),
          ..._flattenSameOperator(rightOperand, isOr: true),
        ],
      LogicalAndPattern(:final leftOperand, :final rightOperand) => [
          ..._flattenSameOperator(leftOperand, isOr: false),
          ..._flattenSameOperator(rightOperand, isOr: false),
        ],
      _ => [node],
    };

List<DartPattern> _flattenSameOperator(
  DartPattern node, {
  required bool isOr,
}) {
  final continuesChain =
      isOr ? node is LogicalOrPattern : node is LogicalAndPattern;

  return continuesChain ? _flatten(node) : [node];
}

class _RemoveDuplicatePattern extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    void check(DartPattern node) {
      if (_isPartOfLargerChain(node)) return;

      final operands = _flatten(node);
      if (!operands.any(
        (operand) => operand.sourceRange == diagnostic.sourceRange,
      )) {
        return;
      }

      // Rewriting the whole chain from its deduplicated operands is correct
      // wherever the duplicate sits, which surgery on the nested nodes is not.
      final seen = <String>{};
      final kept = [
        for (final operand in operands)
          if (seen.add(canonicalize(operand))) operand.toSource(),
      ];
      if (kept.length == operands.length) return;

      final separator = node is LogicalOrPattern ? ' || ' : ' && ';

      final builder = reporter.createChangeBuilder(
        message: 'Remove the duplicated pattern',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        fileBuilder.addSimpleReplacement(
          node.sourceRange,
          kept.join(separator),
        );
      });
    }

    context.registry.addLogicalOrPattern(check);
    context.registry.addLogicalAndPattern(check);
  }
}
