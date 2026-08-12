import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-generics-shadowing',
  category: 'common',
  problemMessage: 'This type parameter has the same name as a type in scope, so '
      'inside this declaration that name no longer means the type.',
  correctionMessage: 'Rename the type parameter.',
  tags: ['readability', 'correctness'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a type parameter shadows a type that is already in scope.
///
/// ```dart
/// class Payload {}
///
/// class Holder<Payload> {
///   final Payload value;   // the parameter, not the class
/// }
/// ```
/// Inside `Holder`, the name `Payload` means the type parameter. Every mention of
/// the real `Payload` in that body silently refers to something else — and because
/// a type parameter accepts anything, nothing in the body fails to compile. The
/// class looks like it constrains its field to a `Payload` and does not.
///
/// The name is looked up in the enclosing library and in every library it imports,
/// through their export namespaces, so a type parameter called `Widget` in a file
/// importing Flutter is reported. Only classes, mixins, enums, extension types and
/// type aliases count as shadowed — a shadowed function or variable is a different
/// question, and not one a type parameter can be confused with.
///
/// No quick-fix is offered: renaming a type parameter means rewriting every use of it
/// in the declaration, which is a rename refactor rather than an edit.
class AvoidGenericsShadowing extends AligRule {
  /// Warns when a type parameter takes a type's name.
  AvoidGenericsShadowing(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((unit) {
      final library = unit.declaredFragment?.element;
      if (library == null) return;

      final visible = _visibleTypeNamesOf(library);
      if (visible.isEmpty) return;

      final visitor = _TypeParameterCollector();
      unit.accept(visitor);

      for (final parameter in visitor.parameters) {
        if (!visible.contains(parameter.name.lexeme)) continue;

        reporter.atToken(parameter.name, code);
      }
    });
  }
}

/// The names of the types visible in [library]: its own, and those every library it
/// imports makes available.
Set<String> _visibleTypeNamesOf(LibraryElement library) {
  final names = <String>{..._ownTypeNamesOf(library)};

  for (final fragment in library.fragments) {
    for (final import in fragment.libraryImports) {
      final imported = import.importedLibrary;
      if (imported == null) continue;

      for (final entry in imported.exportNamespace.definedNames2.entries) {
        if (_isTypeDeclaration(entry.value)) names.add(entry.key);
      }
    }
  }

  return names;
}

Set<String> _ownTypeNamesOf(LibraryElement library) {
  final names = <String>{};
  // Collected per kind: a single spread would widen the element type to Object.
  for (final declaration in library.classes) {
    names.addAll({?declaration.name});
  }
  for (final declaration in library.mixins) {
    names.addAll({?declaration.name});
  }
  for (final declaration in library.enums) {
    names.addAll({?declaration.name});
  }
  for (final declaration in library.extensionTypes) {
    names.addAll({?declaration.name});
  }
  for (final declaration in library.typeAliases) {
    names.addAll({?declaration.name});
  }

  return names;
}

/// Whether [element] is something a type parameter could be mistaken for.
bool _isTypeDeclaration(Element element) =>
    element is InterfaceElement || element is TypeAliasElement;

class _TypeParameterCollector extends RecursiveAstVisitor<void> {
  final parameters = <TypeParameter>[];

  @override
  void visitTypeParameter(TypeParameter node) {
    parameters.add(node);
    super.visitTypeParameter(node);
  }
}
