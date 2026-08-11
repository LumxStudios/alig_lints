import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/shorthand_context.dart';

const _meta = AligRuleMeta(
  name: 'prefer-wildcard-pattern',
  category: 'common',
  problemMessage: 'This type matches everything the value can be, so it is a '
      'wildcard written the long way.',
  correctionMessage: 'Remove the type.',
  tags: ['readability', 'consistency'],
  severity: DiagnosticSeverity.INFO,
);

/// Warns when a wildcard pattern carries a type that excludes nothing.
///
/// `case dynamic _:` and `case Object? _:` match exactly what `case _:` matches,
/// so the type is decoration.
///
/// `case Object _:` is different, and the difference matters: `Object` is
/// non-nullable, so it does *not* match null while a bare `_` does. It is
/// reported only when the value being matched is itself non-nullable, where the
/// two are equivalent. On an `Object?` subject the type is a real null test and
/// is left alone.
class PreferWildcardPattern extends AligRule {
  /// Warns when a wildcard's type excludes nothing.
  PreferWildcardPattern(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addWildcardPattern((node) {
      final type = node.type;
      if (type == null) return;
      if (!_matchesEverything(type, node)) return;

      reporter.atNode(type, code);
    });
  }

  @override
  List<Fix> getFixes() => [_RemoveType()];
}

/// Whether [type] excludes nothing the value at [node] can be.
bool _matchesEverything(TypeAnnotation type, WildcardPattern node) {
  final resolved = type.type;
  if (resolved == null) return false;

  // `dynamic` admits everything, null included.
  if (resolved is DynamicType) return true;

  if (!resolved.isDartCoreObject) return false;

  // `Object?` admits everything too.
  if (resolved.nullabilitySuffix == NullabilitySuffix.question) return true;

  // Bare `Object` excludes null, so it is only redundant when the value cannot
  // be null in the first place.
  final matched = _matchedTypeOf(node);

  return matched != null &&
      matched.nullabilitySuffix == NullabilitySuffix.none &&
      matched is! DynamicType;
}

/// The static type of the value [node] is matched against.
DartType? _matchedTypeOf(AstNode node) {
  final subject = switchSubjectTypeOf(node);
  if (subject != null) return subject;

  final caseClause = node.thisOrAncestorOfType<CaseClause>();
  final parent = caseClause?.parent;

  return switch (parent) {
    IfStatement(:final expression) => expression.staticType,
    IfElement(:final expression) => expression.staticType,
    _ => null,
  };
}

class _RemoveType extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addWildcardPattern((node) {
      final type = node.type;
      if (type == null || type.offset != diagnostic.offset) return;
      if (!_matchesEverything(type, node)) return;

      final builder = reporter.createChangeBuilder(
        message: 'Remove the type',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        // Takes the space after the type with it, leaving a bare `_`.
        fileBuilder.addDeletion(
          SourceRange(type.offset, node.name.offset - type.offset),
        );
      });
    });
  }
}
