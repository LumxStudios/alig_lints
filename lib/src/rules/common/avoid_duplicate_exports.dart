import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/ast_equality.dart';
import '../../common/edit_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-duplicate-exports',
  category: 'common',
  problemMessage: 'This URI is already exported by an earlier export '
      'declaration.',
  correctionMessage: 'Remove this declaration, or merge it into the earlier '
      'one.',
  tags: ['correctness', 'cwe', 'imports'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a file has several `export` declarations for the same URI.
///
/// Catches every repeat of a URI, whether or not the declarations carry the same
/// `show` / `hide` combinators.
///
/// A quick-fix that deletes the declaration is offered only when the duplicate
/// is structurally identical to the earlier one. When the combinators differ,
/// deleting either declaration would change what the library exports, so the
/// duplicate is reported for a human to merge by hand.
class AvoidDuplicateExports extends AligRule {
  /// Warns when a URI is exported more than once.
  AvoidDuplicateExports(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((node) {
      final seen = <String, ExportDirective>{};

      for (final directive in node.directives.whereType<ExportDirective>()) {
        final uri = directive.uri.stringValue;
        if (uri == null) continue;

        final earlier = seen[uri];
        if (earlier == null) {
          seen[uri] = directive;
          continue;
        }
        reporter.atNode(directive, code);
      }
    });
  }

  @override
  List<Fix> getFixes() => [_RemoveDuplicateExport()];
}

class _RemoveDuplicateExport extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addCompilationUnit((node) {
      final exports = node.directives.whereType<ExportDirective>().toList();
      final duplicate = exports
          .where(
            (directive) => directive.sourceRange == diagnostic.sourceRange,
          )
          .firstOrNull;
      if (duplicate == null) return;

      final uri = duplicate.uri.stringValue;
      final earlier = exports
          .where(
            (directive) =>
                directive != duplicate && directive.uri.stringValue == uri,
          )
          .firstOrNull;
      if (earlier == null) return;

      // Deleting the duplicate is only safe when the earlier declaration
      // already exports at least as much: either it carries no combinators, so
      // it exports everything, or both carry identical ones.
      final earlierExportsEverything = earlier.combinators.isEmpty;
      if (!earlierExportsEverything &&
          !_haveSameCombinators(earlier, duplicate)) {
        return;
      }

      final builder = reporter.createChangeBuilder(
        message: 'Remove the duplicate export',
        priority: 80,
      );
      builder.addDartFileEdit((fileBuilder) {
        fileBuilder.addDeletion(lineRangeOf(duplicate, resolver));
      });
    });
  }

  bool _haveSameCombinators(ExportDirective a, ExportDirective b) {
    if (a.combinators.length != b.combinators.length) return false;

    for (var i = 0; i < a.combinators.length; i++) {
      if (!areEquivalent(a.combinators[i], b.combinators[i])) return false;
    }

    return true;
  }
}
