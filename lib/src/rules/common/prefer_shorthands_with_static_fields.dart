import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/shorthand_context.dart';

const _meta = AligRuleMeta(
  name: 'prefer-shorthands-with-static-fields',
  category: 'common',
  problemMessage: 'The expected type already names this class, so the shorthand '
      'says the same thing.',
  correctionMessage: 'Drop the class name and keep the dot.',
  tags: ['readability', 'consistency'],
  severity: DiagnosticSeverity.INFO,
);

/// Suggests the dot shorthand where a static field's type is already known.
///
/// `Job(size: Size.small)` repeats `Size` next to a parameter already declared as
/// one; `size: .small` reads the same.
///
/// Uses the same context rules as `prefer-shorthands-with-enums`, and covers the
/// same positions. Enum values are that rule's, so this one skips them.
class PreferShorthandsWithStaticFields extends AligRule {
  /// Suggests dot shorthands for static fields.
  PreferShorthandsWithStaticFields(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addPrefixedIdentifier((node) {
      final range = _redundantClassNameRangeOf(node);
      if (range == null) return;

      reporter.atOffset(
        offset: range.offset,
        length: range.length,
        diagnosticCode: code,
      );
    });
  }

  @override
  List<Fix> getFixes() => [_UseShorthand()];
}

/// The range of the class name in [node] when the expected type already fixes it.
SourceRange? _redundantClassNameRangeOf(PrefixedIdentifier node) {
  final owner = node.prefix.element;
  // Enum values belong to prefer-shorthands-with-enums.
  if (owner is EnumElement) return null;
  if (owner is! InterfaceElement) return null;

  if (!_isStaticField(node.identifier.element)) return null;
  if (!expectedTypeIs(node, owner)) return null;

  return SourceRange(node.prefix.offset, node.prefix.length);
}

/// Whether [element] is a static field, or the getter a static field induces.
bool _isStaticField(Element? element) => switch (element) {
      FieldElement(:final isStatic) => isStatic,
      GetterElement(:final variable) =>
        variable is FieldElement && variable.isStatic,
      _ => false,
    };

class _UseShorthand extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addPrefixedIdentifier((node) {
      final range = _redundantClassNameRangeOf(node);
      if (range == null || range.offset != diagnostic.offset) return;

      final builder = reporter.createChangeBuilder(
        message: 'Use the shorthand',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        fileBuilder.addDeletion(range);
      });
    });
  }
}
