import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-suspicious-global-reference',
  category: 'common',
  problemMessage: 'This resolves to the top-level declaration, not to the member of '
      'the same name that is in scope here.',
  correctionMessage: 'Write this.name for the member, or rename one of the two.',
  tags: ['correctness', 'cwe'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a name resolves to a global while a member of that name is available.
///
/// ```dart
/// int size = 1;
///
/// class Base {
///   int get size => 2;
/// }
///
/// class Child extends Base {
///   int readSize() => size;   // 1, not 2
/// }
/// ```
/// **Measured, twice**: `Child().readSize()` returns `1`. A member that is only
/// *inherited* — not declared in the class itself — does not win over a library-level
/// declaration of the same name, so the reference silently means the global. Declaring
/// `size` in `Child` itself changes the answer, which is why the mistake survives review:
/// the same line means different things in two classes that look alike. The measurement
/// is recorded in `doc/API_NOTES.md`.
///
/// Extensions have the same hazard: the extended type's members are not in an extension
/// body's lexical scope, so `size` inside `extension OnBase on Base` is the global even
/// though `Base` declares one. Measured at run time as well, for the same reason as the
/// subclass case — this is not a thing to reason about from the spec.
///
/// Reported when a reference resolves to a top-level declaration **and** the surrounding
/// class's ancestry — or the extended type — declares a member with that name. A class
/// that declares the name itself is not reported: there the name means what it looks like.
///
/// No quick-fix is offered. `this.size` and renaming point in opposite directions, and
/// which was meant is the question the report is asking.
class AvoidSuspiciousGlobalReference extends AligRule {
  /// Warns when a global shadows a member that is in scope.
  AvoidSuspiciousGlobalReference(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addSimpleIdentifier((node) {
      if (!_resolvesToTopLevel(node)) return;

      final shadowed = _memberNamesAroundOf(node);
      if (!shadowed.contains(node.name)) return;

      reporter.atNode(node, code);
    });
  }
}

/// Whether [node] resolves to a library-level declaration.
bool _resolvesToTopLevel(SimpleIdentifier node) {
  // A name being declared, or the right-hand side of a `.`, is not a lookup.
  if (node.parent is Declaration) return false;
  if (node.parent is PrefixedIdentifier || node.parent is PropertyAccess) {
    return false;
  }

  final element = node.element;
  if (element == null) return false;
  // A getter, setter, function or variable at library level.
  if (element is! PropertyAccessorElement &&
      element is! TopLevelFunctionElement &&
      element is! TopLevelVariableElement) {
    return false;
  }

  return element.enclosingElement is LibraryElement;
}

/// The member names available around [node] that it could have meant: those an ancestor
/// declares, or those the extended type has.
///
/// Names the enclosing declaration declares itself are excluded — there the reference
/// would already resolve to the member, so there is nothing suspicious about it.
Set<String> _memberNamesAroundOf(SimpleIdentifier node) {
  final owner = node.thisOrAncestorOfType<Declaration>()?.parent;

  if (owner is ClassDeclaration) {
    final element = owner.declaredFragment?.element;
    if (element == null) return const {};

    return _inheritedNamesOf(element)
        .difference(_declaredNamesOf(owner.members));
  }

  if (owner is ExtensionDeclaration) {
    final extended = owner.onClause?.extendedType.type;
    if (extended is! InterfaceType) return const {};

    return _namesOf(extended).difference(_declaredNamesOf(owner.members));
  }

  return const {};
}

/// The member names [element] inherits, excluding `Object`'s.
Set<String> _inheritedNamesOf(InterfaceElement element) {
  final names = <String>{};

  for (final supertype in element.allSupertypes) {
    if (supertype.isDartCoreObject) continue;
    names.addAll(_namesOf(supertype));
  }

  return names;
}

Set<String> _namesOf(InterfaceType type) {
  final names = <String>{};
  final element = type.element;

  for (final getter in element.getters) {
    names.addAll({?getter.name});
  }
  for (final method in element.methods) {
    names.addAll({?method.name});
  }

  return names;
}

Set<String> _declaredNamesOf(List<ClassMember> members) {
  final names = <String>{};

  for (final member in members) {
    if (member is MethodDeclaration) names.add(member.name.lexeme);
    if (member is FieldDeclaration) {
      for (final field in member.fields.variables) {
        names.add(field.name.lexeme);
      }
    }
  }

  return names;
}
