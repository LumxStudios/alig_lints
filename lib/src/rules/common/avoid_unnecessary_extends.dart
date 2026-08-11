import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/edit_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-unnecessary-extends',
  category: 'common',
  problemMessage: 'This is already the default, so the clause adds nothing.',
  correctionMessage: 'Remove the extends clause.',
  tags: ['readability', 'consistency'],
  severity: DiagnosticSeverity.INFO,
);

/// Suggests removing `extends` clauses that restate a default.
///
/// Two defaults are covered:
/// - `class Plain extends Object` — every class extends `Object` already.
/// - `<T extends Object?>` — the implicit bound of a type parameter is `Object?`,
///   on classes, mixins, enums, extensions, functions, methods and typedefs
///   alike.
///
/// `<T extends Object>` is left alone: the non-nullable bound is a real
/// constraint, not the default, and removing it would widen the parameter to
/// accept nullable types.
class AvoidUnnecessaryExtends extends AligRule {
  /// Suggests removing default `extends` clauses.
  AvoidUnnecessaryExtends(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addExtendsClause((node) {
      if (!_isObject(node.superclass)) return;

      reporter.atNode(node, code);
    });

    context.registry.addTypeParameter((node) {
      final bound = node.bound;
      if (bound == null) return;
      if (!_isNullableObject(bound)) return;

      reporter.atNode(bound, code);
    });
  }

  @override
  List<Fix> getFixes() => [_RemoveExtends()];
}

/// Whether [type] is exactly `Object`, without a `?`.
bool _isObject(NamedType type) =>
    type.name.lexeme == 'Object' && type.question == null;

/// Whether [type] is exactly `Object?`, the implicit type parameter bound.
bool _isNullableObject(TypeAnnotation type) =>
    type is NamedType &&
    type.name.lexeme == 'Object' &&
    type.question != null;

class _RemoveExtends extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addExtendsClause((node) {
      if (node.sourceRange != diagnostic.sourceRange) return;

      _delete(
        reporter,
        rangeWithLeadingSpace(node, resolver),
        'Remove the extends clause',
      );
    });

    context.registry.addTypeParameter((node) {
      final bound = node.bound;
      final extendsKeyword = node.extendsKeyword;
      if (bound == null || extendsKeyword == null) return;
      if (bound.sourceRange != diagnostic.sourceRange) return;

      // The bound is reported, but `extends` has to go with it.
      _delete(
        reporter,
        rangeWithLeadingSpaceBetween(extendsKeyword.offset, bound.end, resolver),
        'Remove the bound',
      );
    });
  }

  void _delete(ChangeReporter reporter, SourceRange range, String message) {
    final builder = reporter.createChangeBuilder(message: message, priority: 80);
    builder.addDartFileEdit((fileBuilder) {
      fileBuilder.addDeletion(range);
    });
  }
}
