import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

/// Whether [element] is declared in `package:flutter/src/$libraryPath`.
bool isFlutterElement(Element? element, String libraryPath) {
  final uri = element?.library?.uri;

  return uri != null &&
      uri.scheme == 'package' &&
      uri.path == 'flutter/src/$libraryPath';
}

/// Whether [element] is, or descends from, Flutter's `State`.
bool isStateSubclass(InterfaceElement? element) =>
    hasFlutterSupertype(element, 'State', 'widgets/framework.dart');

/// Whether [element] is, or descends from, Flutter's `Widget`.
bool isWidgetSubclass(InterfaceElement? element) =>
    hasFlutterSupertype(element, 'Widget', 'widgets/framework.dart');

/// Whether [element] is, or descends from, the Flutter class [name] declared in
/// `package:flutter/src/$libraryPath`.
bool hasFlutterSupertype(
  InterfaceElement? element,
  String name,
  String libraryPath,
) {
  if (element == null) return false;

  for (final type in [element.thisType, ...element.allSupertypes]) {
    final declaration = type.element;
    if (declaration.name == name &&
        isFlutterElement(declaration, libraryPath)) {
      return true;
    }
  }

  return false;
}

/// Whether [node] is a call to `State.setState`.
bool isSetStateInvocation(MethodInvocation node) {
  if (node.methodName.name != 'setState') return false;

  return isFlutterElement(node.methodName.element, 'widgets/framework.dart');
}

/// The `State` class declaration enclosing [node], or `null` if there is none.
ClassDeclaration? enclosingStateClass(AstNode node) {
  final declaration = node.thisOrAncestorOfType<ClassDeclaration>();
  if (declaration == null) return null;

  return isStateSubclass(declaration.declaredFragment?.element)
      ? declaration
      : null;
}

/// Whether [type] is Flutter's `BuildContext`.
bool isBuildContext(DartType? type) =>
    type is InterfaceType &&
    type.element.name == 'BuildContext' &&
    isFlutterElement(type.element, 'widgets/framework.dart');
