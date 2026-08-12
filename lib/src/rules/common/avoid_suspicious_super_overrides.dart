import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-suspicious-super-overrides',
  category: 'common',
  problemMessage: 'This getter hides a field the super constructor is given a value '
      'for, so that value is stored and can never be read.',
  correctionMessage: 'Read the inherited field, or stop passing it to super.',
  tags: ['correctness', 'cwe'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a getter hides a field the super constructor is still given.
///
/// ```dart
/// class Base {
///   Base(this.value);
///   final int value;
/// }
///
/// class Child extends Base {
///   Child(super.value);
///
///   @override
///   int get value => 0;
/// }
/// ```
/// **Measured:** `Child(5).value` is `0`, and so is `(Child(5) as Base).value` — the
/// getter wins through virtual dispatch even from a `Base` reference. So the `5` is
/// stored in the inherited field and nothing anywhere can read it. Every caller passing a
/// value is doing work with no effect, and the constructor's signature still asks for it.
///
/// Reported when a class declares a getter, an ancestor declares a **field** of that name,
/// and one of the class's constructors supplies that field to the super constructor —
/// either as `super.value` or as an argument bound to the super constructor's field
/// parameter.
///
/// A subclass that passes the value and leaves the field alone is fine, and so is one that
/// derives from it: `int get doubled => value * 2` reads the stored value rather than
/// replacing it.
///
/// No quick-fix is offered, and the catalogue's fix is deliberately not reproduced. The two
/// repairs contradict each other: deleting the getter changes what every reader of `value`
/// sees, and dropping the super argument changes every constructor call. Which is right
/// depends on whether the stored value or the computed one was meant, and the rule cannot
/// tell.
class AvoidSuspiciousSuperOverrides extends AligRule {
  /// Warns when an override makes a stored value unreachable.
  AvoidSuspiciousSuperOverrides(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      final element = node.declaredFragment?.element;
      if (element == null) return;

      final stored = _fieldsPassedToSuperIn(node);
      if (stored.isEmpty) return;

      final inherited = _inheritedFieldNamesOf(element);

      for (final member in node.members) {
        if (member is! MethodDeclaration || !member.isGetter) continue;

        final name = member.name.lexeme;
        if (!stored.contains(name) || !inherited.contains(name)) continue;

        reporter.atToken(member.name, code);
      }
    });
  }
}

/// The names of the super-constructor fields this class's constructors supply.
Set<String> _fieldsPassedToSuperIn(ClassDeclaration node) {
  final names = <String>{};

  for (final member in node.members) {
    if (member is! ConstructorDeclaration) continue;

    // `Child(super.value)` names the field directly.
    for (final parameter in member.parameters.parameters) {
      final inner =
          parameter is DefaultFormalParameter ? parameter.parameter : parameter;
      if (inner is SuperFormalParameter) names.add(inner.name.lexeme);
    }

    // `: super(value)` binds to the super constructor's own field parameter.
    for (final initializer in member.initializers) {
      if (initializer is! SuperConstructorInvocation) continue;

      for (final argument in initializer.argumentList.arguments) {
        final parameter = argument.correspondingParameter;
        if (parameter != null && parameter.isInitializingFormal) {
          names.addAll({?parameter.name});
        }
      }
    }
  }

  return names;
}

/// The names of the fields [element] inherits.
Set<String> _inheritedFieldNamesOf(InterfaceElement element) {
  final names = <String>{};

  for (final supertype in element.allSupertypes) {
    if (supertype.isDartCoreObject) continue;

    for (final field in supertype.element.fields) {
      if (!field.isStatic) names.addAll({?field.name});
    }
  }

  return names;
}
