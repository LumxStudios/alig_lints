import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-dynamic',
  category: 'common',
  problemMessage: 'Declaring this as dynamic turns off type checking for every '
      'use of it.',
  correctionMessage: 'Write the real type, or `Object?` when the value truly '
      'can be anything.',
  tags: ['maintainability', 'correctness', 'types'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when `dynamic` is written as the type of a declaration.
///
/// ```dart
/// dynamic value;
///
/// void write(dynamic input) => value = input;
/// ```
/// `dynamic` is not a wide type but an absence of one: every member access on
/// the value compiles, and the ones that do not exist fail at run time instead.
/// `Object?` is just as wide and keeps the checking, which is why it is the
/// suggested replacement rather than a specific type.
///
/// Only the whole type of a declaration is reported — a variable, a field, a
/// parameter, or a return type. A `dynamic` inside a type argument is left
/// alone: `Map<String, dynamic>` is the type decoded JSON actually has, and
/// reporting it would fire on the one place `dynamic` is hard to avoid. The
/// narrowing is recorded in `doc/LIMITATIONS.md`.
///
/// The built-in `avoid_dynamic_calls` covers the other half of this ground — the
/// call on a dynamic value rather than the annotation that created it — so the
/// two do not overlap.
///
/// No quick-fix is offered: `Object?` is the safe rewrite but forces a cast or a
/// check at every use, and the type the author meant is usually narrower than
/// either.
class AvoidDynamic extends AligRule {
  /// Warns when a declaration is annotated `dynamic`.
  AvoidDynamic(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addNamedType((node) {
      // Only the literal spelling; an alias for `dynamic` reads as its own name.
      if (node.name.lexeme != 'dynamic') return;
      if (!_isDeclarationType(node)) return;

      reporter.atNode(node, code);
    });
  }
}

/// Whether [node] is the entire type of a declaration rather than a piece of
/// some larger type.
bool _isDeclarationType(NamedType node) => switch (node.parent) {
      VariableDeclarationList(:final type) => type == node,
      SimpleFormalParameter(:final type) => type == node,
      FieldFormalParameter(:final type) => type == node,
      MethodDeclaration(:final returnType) => returnType == node,
      FunctionDeclaration(:final returnType) => returnType == node,
      FunctionTypedFormalParameter(:final returnType) => returnType == node,
      GenericFunctionType(:final returnType) => returnType == node,
      _ => false,
    };
