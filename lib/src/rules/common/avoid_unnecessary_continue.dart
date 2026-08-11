import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/edit_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unnecessary-continue',
  category: 'common',
  problemMessage: 'Nothing follows this continue in the loop body, so it does '
      'not skip anything.',
  correctionMessage: 'Remove the continue.',
  tags: ['control-flow', 'readability'],
  severity: DiagnosticSeverity.INFO,
);

/// Warns when a `continue` is the last statement of a loop body.
///
/// There is nothing left to skip at that point, so the statement only adds noise.
///
/// Deliberately not reported:
/// - Labelled `continue`, which jumps to an enclosing loop and cannot be dropped.
/// - A `continue` that ends an inner block — inside an `if`, or a `switch` case —
///   rather than the loop body itself. There it either guards the statements that
///   follow, or leaves the `switch` as well as continuing the loop, and removing
///   it would either change behaviour or leave an empty block behind.
class AvoidUnnecessaryContinue extends AligRule {
  /// Warns when a trailing `continue` can be removed.
  AvoidUnnecessaryContinue(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addContinueStatement((node) {
      if (!_isRemovable(node)) return;

      reporter.atNode(node, code);
    });
  }

  @override
  List<Fix> getFixes() => [_RemoveContinue()];
}

bool _isRemovable(ContinueStatement node) {
  // `continue outer;` goes somewhere else entirely.
  if (node.label != null) return false;

  final block = node.parent;
  if (block is! Block) return false;
  if (block.statements.last != node) return false;

  // The block must be the loop's own body, not an `if` or `case` inside it.
  return switch (block.parent) {
    ForStatement(:final body) => body == block,
    ForEachPartsWithDeclaration() => false,
    WhileStatement(:final body) => body == block,
    DoStatement(:final body) => body == block,
    _ => false,
  };
}

class _RemoveContinue extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addContinueStatement((node) {
      if (node.sourceRange != diagnostic.sourceRange) return;
      if (!_isRemovable(node)) return;

      final builder = reporter.createChangeBuilder(
        message: 'Remove the continue',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        fileBuilder.addDeletion(lineRangeOf(node, resolver));
      });
    });
  }
}
