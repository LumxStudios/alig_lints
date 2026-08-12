import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'prefer-declaring-const-constructor',
  category: 'common',
  problemMessage: 'Every field here is final and nothing is computed, so this '
      'constructor could be const — and callers cannot make it one themselves.',
  correctionMessage: 'Add const to the constructor.',
  tags: ['performance', 'style'],
  severity: DiagnosticSeverity.INFO,
);

/// Warns when a class with only final fields has a non-const constructor.
///
/// ```dart
/// class Point {
///   Point(this.x, this.y);
///
///   final int x;
///   final int y;
/// }
/// ```
/// `const` on a constructor is not an optimisation the caller can choose later: without
/// it, `const Point(1, 2)` is a compile error, so no caller can put a `Point` in a const
/// context, and identical points are separate objects. Adding it costs nothing and cannot
/// be added by anyone but the class.
///
/// Reported when every instance field is `final` and not `late`, the constructor's body is
/// empty, and no initializer computes anything — the shape where `const` is guaranteed to
/// compile. A class with a mutable field, a `late final` field, a constructor body, or an
/// initializer like `squared = value * value` is left alone.
///
/// A superclass whose own constructor is not `const` also rules it out.
///
/// Neither of those two conditions was in the first version, and each produced a real
/// compile error when the fix was applied across this package's goldens:
/// `late_final_field_with_const_constructor`, and
/// `const_constructor_with_non_const_super` on a Flutter `State` subclass. Both are
/// recorded in `doc/LIMITATIONS.md` — "could be const" has more preconditions than the
/// obvious ones, and the only way to know was to compile the result.
///
/// The fix inserts `const`. It is offered only for that shape, so the result compiles;
/// checking it any more precisely would mean running the const evaluator, which is not
/// available here.
class PreferDeclaringConstConstructor extends AligRule {
  /// Warns when a constructor could be const and is not.
  PreferDeclaringConstConstructor(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addConstructorDeclaration((node) {
      if (!_couldBeConst(node)) return;

      reporter.atNode(node.returnType, code);
    });
  }

  @override
  List<Fix> getFixes() => [_AddConst()];
}

/// Whether `const` would compile on [node].
bool _couldBeConst(ConstructorDeclaration node) {
  if (node.constKeyword != null || node.factoryKeyword != null) return false;

  final owner = node.parent;
  if (owner is! ClassDeclaration) return false;
  // A const constructor cannot exist on a class that can still change.
  if (!_allFieldsAreFinal(owner)) return false;
  if (!_superConstructorIsConst(owner)) return false;

  final body = node.body;
  if (body is! EmptyFunctionBody) return false;

  // Only initializers whose value is a plain reference; anything computed may not be
  // a constant expression, and proving that needs the const evaluator.
  for (final initializer in node.initializers) {
    if (initializer is! ConstructorFieldInitializer) return false;
    if (initializer.expression is! SimpleIdentifier) return false;
  }

  return true;
}

/// Whether the superclass can be reached from a const constructor.
///
/// A const constructor cannot call a non-const super constructor. Flutter's `State` is
/// the case that found this: adding `const` to a `State` subclass's constructor produced
/// `const_constructor_with_non_const_super`.
bool _superConstructorIsConst(ClassDeclaration owner) {
  final supertype = owner.declaredFragment?.element.supertype;
  // Extending Object directly is always fine.
  if (supertype == null || supertype.isDartCoreObject) return true;

  for (final constructor in supertype.constructors) {
    if (constructor.name == 'new') return constructor.isConst;
  }

  return false;
}

bool _allFieldsAreFinal(ClassDeclaration owner) {
  for (final member in owner.members) {
    if (member is! FieldDeclaration || member.isStatic) continue;
    if (!member.fields.isFinal && !member.fields.isConst) return false;
    // `late final` and a generative const constructor cannot coexist: the field is
    // assigned after construction, which is exactly what const forbids. Adding const
    // here is a compile error, which the first version of this rule produced.
    if (member.fields.isLate) return false;
  }

  return true;
}

class _AddConst extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addConstructorDeclaration((node) {
      if (node.returnType.sourceRange != diagnostic.sourceRange) return;
      if (!_couldBeConst(node)) return;

      reporter
          .createChangeBuilder(message: 'Add const', priority: 60)
          .addDartFileEdit((builder) {
        builder.addSimpleInsertion(node.returnType.offset, 'const ');
      });
    });
  }
}
