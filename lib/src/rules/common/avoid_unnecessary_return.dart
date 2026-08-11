import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/edit_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unnecessary-return',
  category: 'common',
  problemMessage: 'Control already leaves the function here, so this return does '
      'nothing.',
  correctionMessage: 'Remove the return.',
  tags: ['control-flow', 'readability'],
  severity: DiagnosticSeverity.INFO,
);

/// Warns when a bare `return;` is the last statement of a function body.
///
/// Control leaves the function at that point anyway. Applies to plain functions,
/// methods, closures, `async` functions and generators alike, since a bare
/// `return;` can only appear where nothing needs returning.
///
/// Deliberately not reported: a `return;` used as a guard clause, which exits
/// early and is the whole point of being there.
class AvoidUnnecessaryReturn extends AligRule {
  /// Warns when a trailing `return;` can be removed.
  AvoidUnnecessaryReturn(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addReturnStatement((node) {
      if (!_isRemovable(node)) return;

      reporter.atNode(node, code);
    });
  }

  @override
  List<Fix> getFixes() => [_RemoveReturn()];
}

bool _isRemovable(ReturnStatement node) {
  // `return value;` is doing something.
  if (node.expression != null) return false;

  final block = node.parent;
  if (block is! Block) return false;
  if (block.statements.last != node) return false;

  // The block has to be the function's own body, not a nested one: a `return;`
  // ending an `if` block is an early exit.
  return block.parent is BlockFunctionBody;
}

class _RemoveReturn extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addReturnStatement((node) {
      if (node.sourceRange != diagnostic.sourceRange) return;
      if (!_isRemovable(node)) return;

      final builder = reporter.createChangeBuilder(
        message: 'Remove the return',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        fileBuilder.addDeletion(lineRangeOf(node, resolver));
      });
    });
  }
}
