import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/constant_conditions.dart';

const _meta = AligRuleMeta(
  name: 'avoid-accessing-collections-by-constant-index',
  category: 'common',
  problemMessage: 'This index never changes, so every pass of the loop reads the '
      'same element.',
  correctionMessage: 'Index by the loop variable, or read the element once '
      'before the loop.',
  tags: ['correctness', 'collections'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a loop body indexes a collection with a constant.
///
/// `for (var i = 0; i < items.length; i++) print(items[0]);` advances `i` and
/// then ignores it. Either the index was meant to vary, or the read belongs
/// outside the loop.
///
/// Only sequence indexing counts. `byName['total']` inside a loop is a map lookup
/// by a fixed key, which is a normal thing to do.
///
/// No quick-fix is offered: whether the index should become the loop variable or
/// the read should move out of the loop depends on what the code meant.
class AvoidAccessingCollectionsByConstantIndex extends AligRule {
  /// Warns when a loop indexes a collection by a constant.
  AvoidAccessingCollectionsByConstantIndex(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addIndexExpression((node) {
      if (!isSyntacticConstant(node.index)) return;
      if (!_isSequence(node.realTarget.staticType)) return;
      if (!_isInsideLoop(node)) return;

      reporter.atNode(node, code);
    });
  }
}

/// Whether [type] is indexed by position rather than by key.
bool _isSequence(DartType? type) {
  if (type is! InterfaceType) return false;

  return type.allSupertypes.any((supertype) => supertype.isDartCoreIterable) ||
      type.isDartCoreList;
}

/// Whether [node] sits in a loop body, rather than in the loop's own header.
bool _isInsideLoop(AstNode node) {
  AstNode? child = node;
  var parent = node.parent;

  while (parent != null) {
    final body = switch (parent) {
      ForStatement(:final body) => body,
      WhileStatement(:final body) => body,
      DoStatement(:final body) => body,
      _ => null,
    };
    if (body != null && body == child) return true;

    child = parent;
    parent = parent.parent;
  }

  return false;
}
