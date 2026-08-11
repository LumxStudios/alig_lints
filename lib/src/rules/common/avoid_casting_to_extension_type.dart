import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/type_system.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-casting-to-extension-type',
  category: 'common',
  problemMessage: 'This cast is checked against the extension type\'s '
      'representation type, not against the extension type itself, so it '
      'cannot fail the way it appears to.',
  correctionMessage: 'Wrap the value in the extension type\'s constructor '
      'instead of casting to it.',
  tags: ['correctness', 'cwe', 'types'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when an expression is cast to an extension type.
///
/// ```dart
/// extension type Meters(int value) {}
///
/// void show(Object object) => print(object as Meters);
/// ```
/// Extension types are erased at run time, so this checks `object is int` and
/// nothing more. Any `int` — a count, an index, a port number — passes a cast
/// that reads as a guarantee of metres, and the mistake surfaces later as a
/// wrong number rather than here as a `TypeError`.
///
/// The honest spelling is the constructor: `Meters(number)` states that the
/// value is being *given* the extension type rather than *found* to have it.
///
/// Casting the other way — from an extension type to its representation type or
/// to `Object` — is not reported. Those casts erase to something the run time
/// really does check.
///
/// The fix rewrites `value as Meters` to `Meters(value)`, but only when that
/// swap is guaranteed to compile: the extension type's primary constructor must
/// be the unnamed one, and the value's static type must already be assignable to
/// the representation type. Otherwise the cast stands and the message explains
/// what to do, since the missing step is a conversion only the author can write.
class AvoidCastingToExtensionType extends AligRule {
  /// Warns when an `as` names an extension type.
  AvoidCastingToExtensionType(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addAsExpression((node) {
      if (_extensionTypeOf(node) == null) return;

      reporter.atNode(node, code);
    });
  }

  @override
  List<Fix> getFixes() => [_UseConstructor()];
}

/// The extension type [node] casts to, or null when it casts to anything else.
ExtensionTypeElement? _extensionTypeOf(AsExpression node) {
  final element = node.type.type?.element;

  return element is ExtensionTypeElement ? element : null;
}

/// The unnamed constructor of [type], or null when it has only named ones.
ConstructorElement? _unnamedConstructorOf(InterfaceType type) {
  for (final constructor in type.constructors) {
    if (constructor.name == 'new') return constructor;
  }

  return null;
}

/// The type system of the library [node] belongs to.
TypeSystem? _typeSystemOf(AstNode node) => node
    .thisOrAncestorOfType<CompilationUnit>()
    ?.declaredFragment
    ?.element
    .typeSystem;

class _UseConstructor extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addAsExpression((node) {
      if (!node.sourceRange.covers(diagnostic.sourceRange)) return;

      if (_extensionTypeOf(node) == null) return;

      // The instantiated type, so that a `Boxed<int>` reports `int` rather than
      // the declaration's type parameter.
      final castType = node.type.type;
      if (castType is! InterfaceType) return;

      // A named primary constructor cannot be called by the type's own name.
      final wrap = _unnamedConstructorOf(castType);
      if (wrap == null || wrap.formalParameters.length != 1) return;

      // Without this the rewrite would swap one error for another.
      final valueType = node.expression.staticType;
      final typeSystem = _typeSystemOf(node);
      if (valueType == null || typeSystem == null) return;
      if (!typeSystem.isAssignableTo(
        valueType,
        wrap.formalParameters.single.type,
      )) {
        return;
      }

      reporter
          .createChangeBuilder(
            message: 'Wrap in ${node.type.toSource()}',
            priority: 60,
          )
          .addDartFileEdit((builder) {
        builder.addSimpleReplacement(
          node.sourceRange,
          '${node.type.toSource()}(${node.expression.toSource()})',
        );
      });
    });
  }
}
