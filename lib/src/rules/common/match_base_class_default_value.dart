import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'match-base-class-default-value',
  category: 'common',
  problemMessage: 'The base class gives this parameter a different default, so which '
      'one applies depends on the static type of the receiver.',
  correctionMessage: "Use the base class's default value.",
  tags: ['correctness', 'cwe'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when an override changes a parameter's default value.
///
/// ```dart
/// abstract class Base {
///   String render(String text, {int width = 80});
/// }
///
/// class Diverging extends Base {
///   @override
///   String render(String text, {int width = 40}) => text;
/// }
/// ```
/// Defaults are filled in by the compiler from the **static** type of the receiver, not
/// from the object. So `Base b = Diverging(); b.render('x')` uses 80, and
/// `Diverging().render('x')` uses 40 — the same object, two answers, decided by how the
/// variable was declared. The bug appears when someone refactors a variable's type,
/// which is a change that looks entirely safe.
///
/// Reported when the override declares a default that differs from the one the
/// overridden member declares for the same parameter, compared by source text. A
/// parameter the base leaves without a default is not reported: adding one there is a
/// choice rather than a contradiction.
///
/// No quick-fix is offered, and the catalogue's fix is deliberately not reproduced.
/// Replacing the override's default with the base's changes behaviour for every caller
/// that relied on it — and if the override's value is the correct one, the repair belongs
/// in the base class instead. The rule cannot tell which of the two is right.
class MatchBaseClassDefaultValue extends AligRule {
  /// Warns when an override's default contradicts the base class.
  MatchBaseClassDefaultValue(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodDeclaration((node) {
      final element = node.declaredFragment?.element;
      final parameters = node.parameters;
      if (element == null || parameters == null) return;

      final inherited = _overriddenDefaultsFor(element);
      if (inherited == null) return;

      for (final parameter in parameters.parameters) {
        if (parameter is! DefaultFormalParameter) continue;

        final written = parameter.defaultValue?.toSource();
        final base = inherited[parameter.name?.lexeme];
        // The base leaving it open is not a contradiction.
        if (written == null || base == null) continue;
        if (written == base) continue;

        reporter.atNode(parameter, code);
      }
    });
  }
}

/// The defaults the member [element] overrides declares, by parameter name, or null
/// when it overrides nothing.
Map<String, String>? _overriddenDefaultsFor(ExecutableElement element) {
  final owner = element.enclosingElement;
  if (owner is! InterfaceElement) return null;

  for (final supertype in owner.allSupertypes) {
    for (final method in supertype.element.methods) {
      if (method.name != element.name) continue;

      final defaults = <String, String>{};
      for (final parameter in method.formalParameters) {
        final name = parameter.name;
        final code = parameter.defaultValueCode;
        if (name != null && code != null) defaults[name] = code;
      }

      return defaults;
    }
  }

  return null;
}
