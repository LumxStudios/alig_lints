import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';

const _meta = AligRuleMeta(
  name: 'avoid-redundant-positional-field-name',
  category: 'common',
  problemMessage: 'A positional record field is reached by position, so this name '
      'is documentation that reads like API.',
  correctionMessage: 'Remove the name, or make the field named.',
  tags: ['correctness'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a positional field of a record type carries a name.
///
/// In `(int count, String)` the `count` is documentation only: the field is still
/// reached as `$1`, and nothing named `count` exists. A reader who sees the name
/// will reasonably expect `.count` to work.
///
/// Named fields — `({int count})` — are unaffected: their names are the API.
class AvoidRedundantPositionalFieldName extends AligRule {
  /// Warns when a positional record field is named.
  AvoidRedundantPositionalFieldName(CustomLintConfigs configs)
      : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addRecordTypeAnnotation((node) {
      for (final field in node.positionalFields) {
        final name = field.name;
        if (name == null) continue;

        reporter.atToken(name, code);
      }
    });
  }

  @override
  List<Fix> getFixes() => [_RemoveFieldName()];
}

class _RemoveFieldName extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addRecordTypeAnnotation((node) {
      for (final field in node.positionalFields) {
        final name = field.name;
        if (name == null || name.offset != diagnostic.offset) continue;

        final builder = reporter.createChangeBuilder(
          message: 'Remove the name',
          priority: 80,
        );
        builder.addDartFileEdit((fileBuilder) {
          // Takes the space before the name too, so `int count` becomes `int`.
          fileBuilder.addDeletion(_rangeWithLeadingSpace(name, resolver));
        });
      }
    });
  }

  SourceRange _rangeWithLeadingSpace(Token name, CustomLintResolver resolver) {
    final source = resolver.source.contents.data;

    var start = name.offset;
    while (start > 0 &&
        (source[start - 1] == ' ' || source[start - 1] == '\t')) {
      start--;
    }

    return SourceRange(start, name.end - start);
  }
}
