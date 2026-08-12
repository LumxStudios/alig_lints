import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-double-slash-imports',
  category: 'common',
  problemMessage: 'This URI has a doubled slash, which resolves today but is not '
      'the path anyone means.',
  correctionMessage: 'Use a single slash.',
  tags: ['style', 'correctness'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when an import or export URI contains `//`.
///
/// ```dart
/// import 'src//helper.dart';
/// ```
/// It resolves — the analyzer normalises the path — so nothing breaks and nothing
/// warns. What it costs is agreement: the same file now has two spellings, so
/// searching for `src/helper.dart` misses this line, and tools that compare URIs
/// as strings treat the two as different files.
///
/// Reported for the URI of any `import`, `export` or `part` directive.
///
/// The fix collapses the doubled slash. It changes only the spelling: the path
/// already resolved to the same file, which is why the mistake survives.
class AvoidDoubleSlashImports extends AligRule {
  /// Warns when a directive's URI has a doubled slash.
  AvoidDoubleSlashImports(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addUriBasedDirective((node) {
      if (!_hasDoubledSlash(node)) return;

      reporter.atNode(node.uri, code);
    });
  }

  @override
  List<Fix> getFixes() => [_CollapseSlashes()];
}

/// Whether [node]'s written URI contains `//` after any scheme.
bool _hasDoubledSlash(UriBasedDirective node) {
  final literal = node.uri.stringValue;
  if (literal == null) return false;

  // A scheme's own `://` is not the mistake.
  final path = literal.contains('://')
      ? literal.substring(literal.indexOf('://') + 3)
      : literal;

  return path.contains('//');
}

class _CollapseSlashes extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addUriBasedDirective((node) {
      if (node.uri.sourceRange != diagnostic.sourceRange) return;

      final literal = node.uri.stringValue;
      if (literal == null) return;

      // Rewrite the written source rather than rebuilding the literal, so the
      // original quoting and any raw prefix survive.
      final written = node.uri.toSource();
      final collapsed = written.replaceAll(RegExp('(?<!:)//+'), '/');

      reporter
          .createChangeBuilder(message: 'Use a single slash', priority: 60)
          .addDartFileEdit((builder) {
        builder.addSimpleReplacement(node.uri.sourceRange, collapsed);
      });
    });
  }
}
