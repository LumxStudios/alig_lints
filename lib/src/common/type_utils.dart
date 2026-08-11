import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/element.dart';
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

/// Whether no value can have both [value] and [tested] as its type.
///
/// Being unrelated is not enough: for two ordinary classes a third one can
/// implement both. One side must be closed — see [_isClosed].
bool areDisjointTypes(DartType? value, DartType? tested, TypeSystem typeSystem) {
  if (value == null || tested == null) return false;
  if (value is! InterfaceType || tested is! InterfaceType) return false;
  // An extension type is erased at run time, so the check is made against its
  // representation type and the declared types predict nothing about it.
  // `avoid-casting-to-extension-type` covers that case with the right reason.
  if (value.element is ExtensionTypeElement ||
      tested.element is ExtensionTypeElement) {
    return false;
  }
  // A null of any declared type satisfies a nullable test.
  if (typeSystem.isNullable(value) && typeSystem.isNullable(tested)) {
    return false;
  }

  final valueType = typeSystem.promoteToNonNull(value);
  final testedType = typeSystem.promoteToNonNull(tested);
  if (typeSystem.isSubtypeOf(valueType, testedType)) return false;
  if (typeSystem.isSubtypeOf(testedType, valueType)) return false;

  return _isClosed(valueType) || _isClosed(testedType);
}

/// Whether nothing outside [type]'s own declaration can be one of its subtypes,
/// so that "not a subtype" really does mean "impossible".
bool _isClosed(DartType type) {
  if (type is! InterfaceType) return false;
  // An enum's instances are fixed by its declaration.
  if (type.element is EnumElement) return true;

  return type.isDartCoreInt ||
      type.isDartCoreDouble ||
      type.isDartCoreString ||
      type.isDartCoreBool ||
      type.isDartCoreNull;
}
