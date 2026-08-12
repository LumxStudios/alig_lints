import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/flutter_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-flexible-outside-flex',
  category: 'flutter',
  problemMessage: 'Flexible only means something inside a Row, Column or Flex; '
      'anywhere else it throws when the layout runs.',
  correctionMessage: 'Put it inside a Flex widget, or drop it and size the child '
      'directly.',
  tags: ['correctness', 'cwe'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a `Flexible` is used outside a `Flex`.
///
/// ```dart
/// Container(
///   child: Flexible(child: Text('c')),
/// )
/// ```
/// `Flexible` writes flex data onto its child's parent data, and only a `Flex`
/// knows how to read it. Anywhere else the framework throws
/// `IncorrectParentDataWidget` during layout — at run time, on the screen that
/// happens to build it, with a message about parent data rather than about the
/// widget that is in the wrong place.
///
/// `Expanded` is a `Flexible`, so it is covered by the same check.
///
/// The parent is found by walking out to the nearest enclosing widget
/// construction. A `Flexible` with none — one returned straight out of `build` —
/// is **not** reported: what it ends up inside is decided by the caller and is not
/// visible here. That is the narrowing worth knowing about, and it is recorded in
/// `doc/LIMITATIONS.md`.
///
/// No quick-fix is offered. Removing the `Flexible` and wrapping the parent in a
/// `Row` are both plausible, and they produce different layouts.
class AvoidFlexibleOutsideFlex extends AligRule {
  /// Warns when a `Flexible` has no `Flex` above it.
  AvoidFlexibleOutsideFlex(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      if (!_isFlexible(node.staticType)) return;

      final parent = _enclosingWidgetType(node);
      // Without a parent in view there is nothing to conclude.
      if (parent == null || _isFlex(parent)) return;

      reporter.atNode(node, code);
    });
  }
}

/// The type of the nearest widget construction [node] sits inside.
DartType? _enclosingWidgetType(AstNode node) {
  for (var current = node.parent; current != null; current = current.parent) {
    if (current is! InstanceCreationExpression) continue;

    final type = current.staticType;
    if (type is InterfaceType && isWidgetSubclass(type.element)) return type;
  }

  return null;
}

bool _isFlexible(DartType? type) =>
    type is InterfaceType &&
    hasFlutterSupertype(type.element, 'Flexible', 'widgets/basic.dart');

bool _isFlex(DartType? type) =>
    type is InterfaceType &&
    hasFlutterSupertype(type.element, 'Flex', 'widgets/basic.dart');
