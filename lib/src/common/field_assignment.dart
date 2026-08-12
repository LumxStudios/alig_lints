import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

/// The private instance fields of [node] with no initializer, which are the only
/// ones whose writers can all be accounted for from the declaration.
///
/// [wantLate] selects which of the two rules is asking: `avoid-unassigned-fields`
/// wants the ordinary fields, `avoid-unassigned-late-fields` the `late` ones. The
/// split exists because the two failures differ — an unwritten ordinary field reads
/// as `null`, an unwritten `late` field throws — and each rule says which happens.
///
/// A field taken as `this.name` by any constructor is excluded: that parameter is the
/// assignment.
List<VariableDeclaration> unassignableCandidatesOf(
  ClassDeclaration node, {
  required bool wantLate,
}) =>
    [
      for (final member in node.members)
        if (member is FieldDeclaration &&
            !member.isStatic &&
            member.fields.isLate == wantLate)
          for (final field in member.fields.variables)
            if (field.initializer == null &&
                field.name.lexeme.startsWith('_') &&
                !_isFieldFormal(node, field.name.lexeme))
              field,
    ];

/// Every element assigned anywhere inside [node], including in initializer lists.
Set<Element> assignedElementsIn(ClassDeclaration node) {
  final visitor = _AssignmentCollector();
  node.accept(visitor);

  return visitor.elements;
}

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
