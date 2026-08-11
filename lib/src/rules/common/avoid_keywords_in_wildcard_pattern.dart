import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-keywords-in-wildcard-pattern',
  category: 'common',
  problemMessage: 'A wildcard binds nothing, so var and final say nothing about '
      'it.',
  correctionMessage: 'Remove the keyword.',
  tags: ['readability'],
  severity: DiagnosticSeverity.INFO,
);

/// Warns when a wildcard pattern carries `var` or `final`.
///
/// `case var _:` and `case final _:` are `case _:`. The keyword describes how a
/// variable is bound, and `_` binds nothing.
///
/// A type annotation is a different matter and stays: `case final int _:` becomes
/// `case int _:`, keeping the type test.
class AvoidKeywordsInWildcardPattern extends AligRule {
  /// Warns when a wildcard pattern has a declaration keyword.
  AvoidKeywordsInWildcardPattern(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addWildcardPattern((node) {
      final keyword = _redundantKeywordOf(node);
      if (keyword == null) return;

      reporter.atToken(keyword, code);
    });
  }

  @override
  List<Fix> getFixes() => [_RemoveKeyword()];
}

/// The `var` or `final` token on [node], or `null` when it has none.
///
/// A `_` pattern is its own node type — `WildcardPattern`, not a
/// `DeclaredVariablePattern` with the name `_` — so there is no name to check
/// here.
Token? _redundantKeywordOf(WildcardPattern node) => node.keyword;

class _RemoveKeyword extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addWildcardPattern((node) {
      final keyword = _redundantKeywordOf(node);
      if (keyword == null || keyword.offset != diagnostic.offset) return;

      final builder = reporter.createChangeBuilder(
        message: 'Remove the keyword',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        // Takes the keyword and the space after it, leaving the type or the `_`.
        fileBuilder.addDeletion(
          SourceRange(keyword.offset, keyword.next!.offset - keyword.offset),
        );
      });
    });
  }
}
