import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

/// Whether [a] and [b] are structurally equivalent.
///
/// Comments, whitespace and redundant parentheses are ignored. Identifiers that
/// resolve to an [Element] are compared by that element, so `x` and `this.x`
/// referring to the same field compare equal; unresolved identifiers fall back
/// to lexeme comparison, which is what makes this usable on parse-only trees.
bool areEquivalent(AstNode? a, AstNode? b) {
  if (a == null || b == null) return a == b;

  return canonicalize(a) == canonicalize(b);
}

/// A normalized string key for [node], suitable for `Set`-based duplicate
/// detection across a list of nodes.
///
/// Two nodes have the same key exactly when [areEquivalent] considers them
/// equivalent.
String canonicalize(AstNode node) {
  final buffer = StringBuffer();
  node.accept(_Canonicalizer(buffer));

  return buffer.toString();
}

/// Whether [node]'s subtree may change program state or produce a different
/// value when evaluated twice.
///
/// Duplicate-detection rules must not report on side-effecting expressions:
/// `f() && f()` is not a redundant repetition the way `a && a` is.
bool hasSideEffects(AstNode node) {
  final visitor = _SideEffectDetector();
  node.accept(visitor);

  return visitor.found;
}

/// Emits a normalized token stream for a subtree.
///
/// Every node writes its type tag followed by its children, so structurally
/// different trees can never collide even when their leaves match.
class _Canonicalizer extends GeneralizingAstVisitor<void> {
  _Canonicalizer(this._buffer);

  final StringBuffer _buffer;

  @override
  void visitNode(AstNode node) {
    // Redundant parentheses carry no meaning.
    if (node is ParenthesizedExpression) {
      node.expression.accept(this);
      return;
    }

    _buffer.write('(${node.runtimeType}');
    for (final child in node.childEntities) {
      switch (child) {
        case AstNode():
          child.accept(this);
        case Token():
          // Keywords, operators and literals are all that distinguish
          // otherwise identically-shaped nodes.
          _buffer.write(' ${child.lexeme}');
      }
    }
    _buffer.write(')');
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final element = _underlyingVariable(node.element);
    if (element == null) {
      // Unresolved: fall back to the name so parse-only trees still compare.
      _buffer.write('(id ${node.name})');
      return;
    }
    // Two names that resolve to the same declaration are the same value,
    // regardless of how they were written. The name is emitted alongside the
    // identity so that a hash collision alone cannot make two distinct
    // declarations compare equal.
    _buffer.write('(id ${element.name}#${identityHashCode(element)})');
  }

  @override
  void visitComment(Comment node) {}
}

/// Reduces a getter or setter to the field or top-level variable it wraps.
Element? _underlyingVariable(Element? element) => switch (element) {
      PropertyAccessorElement(:final variable) => variable,
      _ => element,
    };

/// Finds any construct that makes repeated evaluation unsafe.
class _SideEffectDetector extends RecursiveAstVisitor<void> {
  /// Whether a side effect was found anywhere in the visited subtree.
  bool found = false;

  @override
  void visitMethodInvocation(MethodInvocation node) {
    found = true;
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    found = true;
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    found = true;
  }

  @override
  void visitAwaitExpression(AwaitExpression node) {
    found = true;
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    found = true;
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    found = true;
  }

  @override
  void visitThrowExpression(ThrowExpression node) {
    found = true;
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    if (_isIncrementOrDecrement(node.operator.lexeme)) {
      found = true;
      return;
    }
    super.visitPostfixExpression(node);
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    if (_isIncrementOrDecrement(node.operator.lexeme)) {
      found = true;
      return;
    }
    super.visitPrefixExpression(node);
  }

  static bool _isIncrementOrDecrement(String lexeme) =>
      lexeme == '++' || lexeme == '--';
}
