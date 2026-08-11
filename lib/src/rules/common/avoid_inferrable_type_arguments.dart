import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-inferrable-type-arguments',
  category: 'common',
  problemMessage: 'These type arguments repeat what the surrounding type '
      'already says, so inference would reach the same type without them.',
  correctionMessage: 'Remove the type arguments.',
  tags: ['readability', 'consistency', 'types'],
  severity: DiagnosticSeverity.INFO,
);

/// Warns when explicit type arguments repeat the type the context already gives.
///
/// ```dart
/// final List<int> declared = <int>[];
/// ```
/// The annotation on the left already fixes the element type, so `[]` builds the
/// same `List<int>`. Writing it twice means both spellings have to be kept in
/// step by hand.
///
/// Removal is only reported where it is *provably* safe: the type the context
/// supplies must be exactly the type the expression already has. That covers
/// three positions — a variable or field with a written type, an argument whose
/// parameter type spells it, and a return in a function with a declared return
/// type.
///
/// Everything else is left alone, and deliberately:
///
/// - `final inferred = <int>[]` has no context type, so removing the arguments
///   would produce `List<dynamic>`;
/// - `final List<num> widened = <int>[]` has a context type that differs, so
///   removing them would change what is built;
/// - generic *method* calls such as `identity<int>(x)` infer from their
///   arguments as well as their context, which cannot be re-run from here.
///
/// Deciding this by re-running inference is what a whole-program engine would
/// do; the equality test used here reports less but never reports code whose
/// meaning would change. The gap is recorded in `doc/LIMITATIONS.md`.
class AvoidInferrableTypeArguments extends AligRule {
  /// Warns when type arguments duplicate the context type.
  AvoidInferrableTypeArguments(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addTypedLiteral((node) {
      final arguments = node.typeArguments;
      if (arguments != null && _isRedundant(node)) {
        reporter.atNode(arguments, code);
      }
    });

    context.registry.addInstanceCreationExpression((node) {
      final arguments = node.constructorName.type.typeArguments;
      if (arguments != null && _isRedundant(node)) {
        reporter.atNode(arguments, code);
      }
    });
  }

  @override
  List<Fix> getFixes() => [_RemoveTypeArguments()];
}

/// Whether the context around [node] already produces [node]'s exact type.
bool _isRedundant(Expression node) {
  final type = node.staticType;
  if (type == null) return false;

  final context = _contextTypeOf(node);

  return context != null && context == type;
}

/// The type the surrounding code demands of [node], or null when the context
/// does not spell one out.
DartType? _contextTypeOf(Expression node) {
  final parent = node.parent;

  if (parent is VariableDeclaration && parent.initializer == node) {
    final list = parent.parent;

    return list is VariableDeclarationList ? list.type?.type : null;
  }

  if (parent is ArgumentList || parent is NamedExpression) {
    return node.correspondingParameter?.type;
  }

  if (parent is ReturnStatement || parent is ExpressionFunctionBody) {
    return _declaredReturnTypeOf(node);
  }

  return null;
}

/// The written return type of the function [node] returns from, but only when
/// the body is a plain synchronous one — `async` and `sync*` bodies wrap the
/// value, so the declared type is not the type of the returned expression.
DartType? _declaredReturnTypeOf(Expression node) {
  final body = node.thisOrAncestorOfType<FunctionBody>();
  if (body == null || body.isAsynchronous || body.isGenerator) return null;

  return switch (body.parent) {
    MethodDeclaration(:final returnType) => returnType?.type,
    FunctionDeclaration(:final returnType) => returnType?.type,
    FunctionExpression(parent: FunctionDeclaration(:final returnType)) =>
      returnType?.type,
    _ => null,
  };
}

class _RemoveTypeArguments extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addTypeArgumentList((node) {
      if (node.sourceRange != diagnostic.sourceRange) return;

      reporter
          .createChangeBuilder(message: 'Remove the type arguments', priority: 60)
          .addDartFileEdit((builder) {
        builder.addDeletion(node.sourceRange);
      });
    });
  }
}
