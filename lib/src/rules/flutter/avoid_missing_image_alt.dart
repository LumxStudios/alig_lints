import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/flutter_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-missing-image-alt',
  category: 'flutter',
  problemMessage: 'This image has no semanticLabel, so a screen reader announces '
      'nothing where it is.',
  correctionMessage: 'Add a semanticLabel describing the image, or set '
      'excludeFromSemantics: true if it is decorative.',
  tags: ['accessibility', 'flutter'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when an `Image` has no `semanticLabel`.
///
/// ```dart
/// Image.asset('chart.png')
/// ```
/// To a screen reader this is a gap: the user is told there is an image and
/// nothing about what it shows. Where the image carries the information — a chart,
/// a status icon, a photo being described — the content is simply lost.
///
/// Setting `excludeFromSemantics: true` also satisfies the rule. That is the right
/// answer for decoration, and stating it is what distinguishes "this image says
/// nothing" from "nobody thought about it".
///
/// Reported for every `Image` constructor: the unnamed one, `Image.asset`,
/// `Image.network`, `Image.file` and `Image.memory`.
///
/// No quick-fix is offered, and the catalogue's fix is deliberately not
/// reproduced. A fix could only insert an empty label, and an empty label reads to
/// a screen reader exactly like the missing one — it would close the report
/// without helping anybody. The text is the whole point, and only the author knows
/// what the image shows.
class AvoidMissingImageAlt extends AligRule {
  /// Warns when an image has nothing for a screen reader to say.
  AvoidMissingImageAlt(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final type = node.staticType;
      if (type is! InterfaceType) return;
      if (!hasFlutterSupertype(type.element, 'Image', 'widgets/image.dart')) {
        return;
      }

      final names = _argumentNamesOf(node);
      if (names.contains('semanticLabel')) return;
      if (names.contains('excludeFromSemantics')) return;

      reporter.atNode(node.constructorName, code);
    });
  }
}

/// The names of every named argument passed to [node].
Set<String> _argumentNamesOf(InstanceCreationExpression node) => {
      for (final argument in node.argumentList.arguments)
        if (argument is NamedExpression) argument.name.label.name,
    };
