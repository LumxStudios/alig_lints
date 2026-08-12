import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/flutter_utils.dart';

const _meta = AligRuleMeta(
  name: 'prefer-dedicated-media-query-methods',
  category: 'flutter',
  problemMessage: 'Reading one property through MediaQuery.of subscribes this '
      'widget to every MediaQuery change, not just the one it uses.',
  correctionMessage: 'Use the dedicated method for that property.',
  tags: ['performance', 'flutter'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when `MediaQuery.of` is used to read a property that has its own method.
///
/// ```dart
/// final size = MediaQuery.of(context).size;
/// ```
/// `MediaQuery.of` registers a dependency on the whole `MediaQueryData`, so the
/// widget rebuilds when the keyboard opens, when the text scale changes, when
/// anything in there changes — even though it only reads `size`.
/// `MediaQuery.sizeOf(context)` depends on that one property, and Flutter added
/// these methods precisely so a rebuild can be avoided.
///
/// The dedicated method is looked up on `MediaQuery` itself rather than compared
/// against a hardcoded list, so properties Flutter adds later are covered without
/// a change here. `maybeOf` maps to the `maybe…Of` form.
///
/// `MediaQuery.of(context)` on its own — assigned to a variable, or passed on — is
/// not reported. The whole data really is being used, and which property matters is
/// no longer visible at that point.
///
/// The fix rewrites the expression to the dedicated call, keeping the same
/// argument. It only fires when that method exists, so the result compiles.
class PreferDedicatedMediaQueryMethods extends AligRule {
  /// Warns when a single MediaQuery property is read through `of`.
  PreferDedicatedMediaQueryMethods(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addPropertyAccess((node) {
      if (_dedicatedCallFor(node) == null) return;

      reporter.atNode(node, code);
    });
  }

  @override
  List<Fix> getFixes() => [_UseDedicatedMethod()];
}

/// The replacement source for [node], or null when this is not a single-property
/// read through `MediaQuery.of`.
String? _dedicatedCallFor(PropertyAccess node) {
  final lookup = node.target;
  if (lookup is! MethodInvocation) return null;

  final name = lookup.methodName.name;
  if (name != 'of' && name != 'maybeOf') return null;

  final mediaQuery = _mediaQueryClassOf(lookup);
  if (mediaQuery == null) return null;

  final property = node.propertyName.name;
  final capitalised = property[0].toUpperCase() + property.substring(1);
  final dedicated =
      name == 'of' ? '${property}Of' : 'maybe${capitalised}Of';

  // Looked up rather than assumed, so a property with no dedicated method — or
  // one Flutter has not added yet — is left alone.
  if (mediaQuery.getMethod(dedicated) == null) return null;

  final arguments = lookup.argumentList.toSource();

  return 'MediaQuery.$dedicated$arguments';
}

/// The `MediaQuery` class [lookup] is a static call on, or null if it is not one.
InterfaceElement? _mediaQueryClassOf(MethodInvocation lookup) {
  final type = lookup.staticType;
  if (type is! InterfaceType) return null;
  if (!isFlutterElement(type.element, 'widgets/media_query.dart')) return null;
  if (type.element.name != 'MediaQueryData') return null;

  final target = lookup.target;
  if (target is! SimpleIdentifier) return null;

  final element = target.element;

  return element is InterfaceElement && element.name == 'MediaQuery'
      ? element
      : null;
}

class _UseDedicatedMethod extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addPropertyAccess((node) {
      if (node.sourceRange != diagnostic.sourceRange) return;

      final replacement = _dedicatedCallFor(node);
      if (replacement == null) return;

      reporter
          .createChangeBuilder(
            message: 'Use the dedicated method',
            priority: 60,
          )
          .addDartFileEdit((builder) {
        builder.addSimpleReplacement(node.sourceRange, replacement);
      });
    });
  }
}
