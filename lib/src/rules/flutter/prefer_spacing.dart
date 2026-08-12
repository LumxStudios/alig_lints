import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/flutter_utils.dart';

const _meta = AligRuleMeta(
  name: 'prefer-spacing',
  category: 'flutter',
  problemMessage: 'This box exists only to leave a gap, which the parent can do '
      'with its spacing argument.',
  correctionMessage: "Remove the boxes and set the parent's spacing.",
  tags: ['maintainability', 'style'],
  severity: DiagnosticSeverity.INFO,
);

/// Warns when `SizedBox` widgets are used as gaps inside a `Flex`.
///
/// ```dart
/// Column(
///   children: [
///     Text('a'),
///     SizedBox(height: 8),
///     Text('b'),
///   ],
/// )
/// ```
/// `Row`, `Column` and `Flex` take a `spacing` argument that puts the same gap
/// between every child. Spacer boxes do the same thing in more lines, and they
/// drift: adding a child means remembering to add a box, and changing the gap means
/// editing each one.
///
/// Reported for a `SizedBox` **between** two other children whose only argument is
/// the dimension along the parent's axis — `height` in a `Column`, `width` in a
/// `Row`.
///
/// Two shapes are deliberately left alone. A box at the start or end of the list is
/// padding rather than a gap, and `spacing` would not reproduce it. A box with a
/// `child` is a widget in its own right.
///
/// No quick-fix is offered. Replacing the boxes with `spacing` is only equivalent
/// when every gap is the same size, and where they differ the rule has no way to
/// choose which one the parent should take.
class PreferSpacing extends AligRule {
  /// Warns when spacer boxes stand in for the parent's spacing.
  PreferSpacing(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final axis = _flexAxisOf(node.staticType);
      if (axis == null) return;

      final children = _childrenOf(node);
      if (children == null) return;

      for (var i = 1; i < children.length - 1; i++) {
        final child = children[i];
        if (child is! InstanceCreationExpression) continue;
        if (!_isGapBox(child, axis)) continue;

        reporter.atNode(child, code);
      }
    });
  }
}

/// The argument name a gap along this `Flex`'s axis would use, or null when [type]
/// is not a `Flex`.
String? _flexAxisOf(DartType? type) {
  if (type is! InterfaceType) return null;
  if (!hasFlutterSupertype(type.element, 'Flex', 'widgets/basic.dart')) {
    return null;
  }

  // Row is horizontal, Column and a bare Flex are treated as vertical unless the
  // widget itself says otherwise.
  final name = type.element.name;

  return name == 'Row' ? 'width' : 'height';
}

/// The elements of the `children:` list, or null when it is not a plain list.
List<CollectionElement>? _childrenOf(InstanceCreationExpression node) {
  for (final argument in node.argumentList.arguments) {
    if (argument is! NamedExpression) continue;
    if (argument.name.label.name != 'children') continue;

    final value = argument.expression;

    return value is ListLiteral ? value.elements.toList() : null;
  }

  return null;
}

/// Whether [node] is a `SizedBox` whose only purpose is a gap along [axis].
bool _isGapBox(InstanceCreationExpression node, String axis) {
  final type = node.staticType;
  if (type is! InterfaceType) return false;
  if (!hasFlutterSupertype(type.element, 'SizedBox', 'widgets/basic.dart')) {
    return false;
  }

  final names = {
    for (final argument in node.argumentList.arguments)
      if (argument is NamedExpression) argument.name.label.name,
  };

  // A box with a child is a widget; one sized on the other axis is not a gap.
  return names.length == 1 && names.single == axis;
}
