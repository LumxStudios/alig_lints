import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

/// Whether any variable or field read by [expression] is written to anywhere
/// inside [region].
///
/// Rules that claim a condition still holds further down — "the outer `if`
/// already established this" — must not do so across a reassignment. The check
/// deliberately ignores *where* in [region] the write happens: a write after the
/// point of interest still suppresses the report. That costs some true positives
/// and rules out false ones, which is the right trade for a lint.
bool isMutatedWithin(AstNode region, Expression expression) {
  final read = elementsReadBy(expression);
  if (read.isEmpty) return false;

  return read.intersection(elementsWrittenBy(region)).isNotEmpty;
}

/// The declarations [node] reads.
Set<Element> elementsReadBy(AstNode node) {
  final visitor = _ReferencedElements();
  node.accept(visitor);

  return visitor.elements;
}

/// The declarations [node] writes to.
Set<Element> elementsWrittenBy(AstNode node) {
  final visitor = _WrittenElements();
  node.accept(visitor);

  return visitor.elements;
}

/// Collects the declarations an expression reads.
class _ReferencedElements extends RecursiveAstVisitor<void> {
  final elements = <Element>{};

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final element = _underlyingVariable(node.element);
    if (element != null) elements.add(element);
  }
}

/// Collects the declarations a region writes to.
class _WrittenElements extends RecursiveAstVisitor<void> {
  final elements = <Element>{};

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    _add(node.writeElement);
    super.visitAssignmentExpression(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    _add(node.writeElement);
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    _add(node.writeElement);
    super.visitPrefixExpression(node);
  }

  void _add(Element? element) {
    final variable = _underlyingVariable(element);
    if (variable != null) elements.add(variable);
  }
}

/// Reduces a getter or setter to the field or top-level variable it wraps, so
/// that a read and a write of the same property compare equal.
Element? _underlyingVariable(Element? element) => switch (element) {
      PropertyAccessorElement(:final variable) => variable,
      _ => element,
    };
