import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-explicit-pattern-field-name',
  category: 'common',
  problemMessage: 'The field name repeats the variable name, so the shorthand '
      'says the same thing.',
  correctionMessage: 'Drop the field name and keep the colon.',
  tags: ['readability', 'consistency'],
  severity: DiagnosticSeverity.INFO,
);

/// Warns when an object or record pattern names a field the shorthand covers.
///
/// `Point(x: var x, y: var y)` is `Point(:var x, :var y)`: when the bound variable
/// has the same name as the field, the name before the colon adds nothing.
///
/// A pattern that renames — `Point(x: var horizontal)` — needs the explicit name
/// and is left alone.
class AvoidExplicitPatternFieldName extends AligRule {
  /// Warns when a pattern field name duplicates its variable name.
  AvoidExplicitPatternFieldName(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addPatternField((node) {
      final name = _redundantNameOf(node);
      if (name == null) return;

      reporter.atToken(name, code);
    });
  }

  @override
  List<Fix> getFixes() => [_DropFieldName()];
}

/// The field-name token that the shorthand would cover, or `null`.
Token? _redundantNameOf(PatternField node) {
  final fieldName = node.name;
  final name = fieldName?.name;
  if (fieldName == null || name == null) return null;

  final pattern = node.pattern;
  final boundName = switch (pattern) {
    DeclaredVariablePattern(:final name) => name.lexeme,
    AssignedVariablePattern(:final name) => name.lexeme,
    _ => null,
  };

  return boundName == name.lexeme ? name : null;
}

class _DropFieldName extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addPatternField((node) {
      final name = _redundantNameOf(node);
      if (name == null || name.offset != diagnostic.offset) return;

      final builder = reporter.createChangeBuilder(
        message: 'Use the shorthand',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        // Replaces `name: ` with `:` so the result is the idiomatic `:var x`
        // rather than `: var x`, which deleting the name alone would leave.
        fileBuilder.addSimpleReplacement(
          SourceRange(name.offset, node.pattern.offset - name.offset),
          ':',
        );
      });
    });
  }
}
