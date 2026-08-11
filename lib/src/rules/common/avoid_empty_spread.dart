import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/edit_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-empty-spread',
  category: 'common',
  problemMessage: 'Spreading an empty collection contributes nothing.',
  correctionMessage: 'Remove the spread.',
  tags: ['correctness', 'cwe', 'collections'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a spread expands an empty collection literal.
///
/// `[...numbers, ...[]]` is `[...numbers]`. Usually a leftover from an edit, or a
/// placeholder where elements were meant to go.
///
/// Only literals written in place are recognised, so a spread of an empty variable
/// is not reported: whether it stays empty is a runtime question.
class AvoidEmptySpread extends AligRule {
  /// Warns when an empty collection literal is spread.
  AvoidEmptySpread(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addSpreadElement((node) {
      if (!_isEmptyLiteral(node.expression)) return;

      reporter.atNode(node, code);
    });
  }

  @override
  List<Fix> getFixes() => [_RemoveSpread()];
}

bool _isEmptyLiteral(Expression expression) => switch (expression
    .unParenthesized) {
      ListLiteral(:final elements) => elements.isEmpty,
      SetOrMapLiteral(:final elements) => elements.isEmpty,
      _ => false,
    };

class _RemoveSpread extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addSpreadElement((node) {
      if (node.sourceRange != diagnostic.sourceRange) return;
      if (!_isEmptyLiteral(node.expression)) return;

      final builder = reporter.createChangeBuilder(
        message: 'Remove the spread',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        fileBuilder.addDeletion(rangeRemovingListItem(node, resolver));
      });
    });
  }
}
