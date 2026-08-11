import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'prefer-simpler-patterns-null-check',
  category: 'common',
  problemMessage: 'This pattern only checks for null, which a comparison says '
      'more directly.',
  correctionMessage: 'Compare against null instead.',
  tags: ['readability', 'maintainability', 'nullability'],
  severity: DiagnosticSeverity.INFO,
);

/// Warns when an `if`-case does nothing but test for null.
///
/// `if (value case != null)` and `if (value case _?)` are `if (value != null)`.
/// The pattern form buys nothing when it binds no name — and Dart promotes the
/// variable either way.
///
/// Left alone, because each does more than test for null:
/// - `if (value case final bound?)`, which names the promoted value;
/// - `if (value case int _?)`, which also tests the type;
/// - anything carrying a `when` guard, which needs the pattern form.
class PreferSimplerPatternsNullCheck extends AligRule {
  /// Warns when a null-check pattern can be a comparison.
  PreferSimplerPatternsNullCheck(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCaseClause((node) {
      if (_comparisonFor(node) == null) return;

      reporter.atNode(node, code);
    });
  }

  @override
  List<Fix> getFixes() => [_UseComparison()];
}

/// The comparison operator [node]'s pattern amounts to, or `null` when the
/// pattern does more than test for null.
String? _comparisonFor(CaseClause node) {
  final guarded = node.guardedPattern;
  if (guarded.whenClause != null) return null;

  final pattern = guarded.pattern;

  // `case != null` and `case == null`.
  if (pattern is RelationalPattern) {
    if (pattern.operand.unParenthesized is! NullLiteral) return null;

    final operator = pattern.operator.lexeme;

    return operator == '==' || operator == '!=' ? operator : null;
  }

  // `case _?`, but not `case int _?` or `case final bound?`.
  if (pattern is NullCheckPattern) {
    final inner = pattern.pattern;

    return inner is WildcardPattern && inner.type == null ? '!=' : null;
  }

  return null;
}

class _UseComparison extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addCaseClause((node) {
      if (node.sourceRange != diagnostic.sourceRange) return;

      final operator = _comparisonFor(node);
      if (operator == null) return;

      final parent = node.parent;
      final subject = switch (parent) {
        IfStatement(:final expression) => expression,
        IfElement(:final expression) => expression,
        _ => null,
      };
      if (subject == null) return;

      final builder = reporter.createChangeBuilder(
        message: 'Compare against null',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        // Replaces `<subject> case <pattern>` with `<subject> <op> null`.
        fileBuilder.addSimpleReplacement(
          SourceRange(subject.offset, node.end - subject.offset),
          '${subject.toSource()} $operator null',
        );
      });
    });
  }
}
