import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unassigned-fields',
  category: 'common',
  problemMessage: 'Nothing in this class ever assigns this field, so it keeps its '
      'initial value forever.',
  correctionMessage: 'Assign it, give it an initializer, or remove it.',
  tags: ['unused-code', 'correctness'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a private field is never assigned a value.
///
/// ```dart
/// class Holder {
///   int? _never;
///
///   int get total => _never ?? 0;
/// }
/// ```
/// The field is read, so nothing calls it unused — but nothing ever writes it, so
/// every read gets `null`. The code around it looks like it handles a value that
/// arrives from somewhere, and no such value exists. This is what a half-finished
/// refactor leaves behind: the writer was removed and the reader stayed.
///
/// **Measured:** the analyzer's `unused_field` reports a field whose *value* is never
/// read. A field that is read but never written falls outside it, and nothing else
/// covers it; the measurement is in `doc/LIMITATIONS.md`.
///
/// Only private fields, because only for those can the whole set of writers be seen.
/// A public field can be assigned by anything that holds the object.
///
/// A field with an initializer, a field formal (`this._value`) and a field assigned
/// anywhere in the class — a constructor body, a method, a `late final` set up later
/// — all count as assigned.
///
/// No quick-fix is offered. Removing the field means removing every read of it, and
/// the alternative — finding what should have written it — is the repair the report
/// is asking for.
class AvoidUnassignedFields extends AligRule {
  /// Warns when nothing writes a private field.
  AvoidUnassignedFields(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      final assigned = _assignedElementsIn(node);

      for (final field in _candidateFieldsOf(node)) {
        final element = field.declaredFragment?.element;
        if (element == null) continue;
        if (assigned.contains(element)) continue;

        reporter.atToken(field.name, code);
      }
    });
  }
}

/// The private instance fields with no initializer, which are the only ones whose
/// writers can all be accounted for.
List<VariableDeclaration> _candidateFieldsOf(ClassDeclaration node) => [
      for (final member in node.members)
        if (member is FieldDeclaration && !member.isStatic)
          for (final field in member.fields.variables)
            if (field.initializer == null &&
                field.name.lexeme.startsWith('_') &&
                !_isFieldFormal(node, field.name.lexeme))
              field,
    ];

/// Whether any constructor takes this field as `this.name`, which assigns it.
bool _isFieldFormal(ClassDeclaration node, String name) {
  for (final member in node.members) {
    if (member is! ConstructorDeclaration) continue;

    for (final parameter in member.parameters.parameters) {
      final inner = parameter is DefaultFormalParameter
          ? parameter.parameter
          : parameter;
      if (inner is FieldFormalParameter && inner.name.lexeme == name) {
        return true;
      }
    }
  }

  return false;
}

/// Every element assigned anywhere inside the class, including in initializer
/// lists.
Set<Element> _assignedElementsIn(ClassDeclaration node) {
  final visitor = _AssignmentCollector();
  node.accept(visitor);

  return visitor.elements;
}

class _AssignmentCollector extends RecursiveAstVisitor<void> {
  final elements = <Element>{};

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    final written = node.writeElement;
    if (written != null) elements.add(_fieldOf(written));
    super.visitAssignmentExpression(node);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    final element = node.fieldName.element;
    if (element != null) elements.add(_fieldOf(element));
    super.visitConstructorFieldInitializer(node);
  }
}

/// The field behind a write, which resolves to the setter rather than the field.
Element _fieldOf(Element element) =>
    element is PropertyAccessorElement ? element.variable : element;
