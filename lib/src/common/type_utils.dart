import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';

/// The type system of the library [node] belongs to, or null when the unit is
/// not resolved.
///
/// Rules need this to ask subtype questions, which the AST alone cannot answer.
TypeSystem? typeSystemOf(AstNode node) => node
    .thisOrAncestorOfType<CompilationUnit>()
    ?.declaredFragment
    ?.element
    .typeSystem;

/// The element type of [type] when it is an iterable, or null otherwise.
DartType? iterableElementTypeOf(DartType? type) {
  if (type is! InterfaceType) return null;
  if (type.isDartCoreIterable) return type.typeArguments.firstOrNull;

  for (final supertype in type.allSupertypes) {
    if (supertype.isDartCoreIterable) return supertype.typeArguments.firstOrNull;
  }

  return null;
}
