import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/flutter_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-incorrect-image-opacity',
  category: 'flutter',
  problemMessage: 'Wrapping an Image in Opacity forces a save layer for '
      'something the Image can do itself.',
  correctionMessage: "Pass the Image's own opacity parameter instead.",
  tags: ['performance', 'flutter'],
  severity: DiagnosticSeverity.INFO,
);

/// Warns when an `Image` is wrapped in an `Opacity`.
///
/// ```dart
/// Opacity(
///   opacity: 0.5,
///   child: Image.asset('a.png'),
/// )
/// ```
/// `Opacity` makes the compositor allocate an offscreen layer, paint the subtree
/// into it, then blend it. `Image` accepts an `opacity` animation and applies it
/// while painting, with no extra layer. The output looks the same; the cost does
/// not, and it is paid on every frame the image is on screen.
///
/// Reported only when the `Opacity`'s `child` is directly an `Image`. An `Opacity`
/// over anything else genuinely needs the layer, and one with an `Image` further
/// down its subtree may be blending it with siblings.
///
/// No quick-fix is offered. `Image.opacity` takes an `Animation<double>` rather
/// than a number, so the rewrite has to introduce an
/// `AlwaysStoppedAnimation(0.5)` — and where the surrounding code already has an
/// animation driving the value, that would be the wrong answer.
class AvoidIncorrectImageOpacity extends AligRule {
  /// Warns when an `Opacity` wraps an `Image` directly.
  AvoidIncorrectImageOpacity(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      if (!_isFlutterWidget(node.staticType, 'Opacity', 'widgets/basic.dart')) {
        return;
      }

      final child = _namedArgument(node, 'child');
      if (child == null) return;
      if (!_isFlutterWidget(child.staticType, 'Image', 'widgets/image.dart')) {
        return;
      }

      reporter.atNode(node, code);
    });
  }
}

/// The expression passed as [name], or null when the call does not pass it.
Expression? _namedArgument(InstanceCreationExpression node, String name) {
  for (final argument in node.argumentList.arguments) {
    if (argument is NamedExpression && argument.name.label.name == name) {
      return argument.expression;
    }
  }

  return null;
}

bool _isFlutterWidget(DartType? type, String name, String libraryPath) =>
    type is InterfaceType &&
    hasFlutterSupertype(type.element, name, libraryPath);
