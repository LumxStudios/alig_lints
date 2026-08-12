import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart' hide LintCode;
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

import '../../common/alig_rule.dart';
import '../../common/edit_utils.dart';

const _meta = AligRuleMeta(
  name: 'avoid-commented-out-code',
  category: 'common',
  problemMessage: 'This comment is code, not an explanation, so it is read as '
      'history nobody can trust.',
  correctionMessage: 'Delete it — version control already remembers it.',
  tags: ['unused-code', 'readability'],
  severity: DiagnosticSeverity.WARNING,
);

/// Warns when a comment contains code rather than prose.
///
/// ```dart
/// // print('debugging');
/// // final old = compute();
/// ```
/// Commented-out code is a claim with no owner: nobody knows whether it is a
/// half-finished change, something kept "just in case", or a line disabled during an
/// incident and forgotten. It does not compile, so it is never checked and drifts out
/// of date silently — and it survives forever, because deleting someone else's
/// commented code always feels like it might matter. Version control already keeps
/// it, with an author and a date attached.
///
/// **How code is told from prose:** the comment's text is handed to the Dart parser,
/// once as a compilation unit and once wrapped in a function body. If either parses
/// without a single diagnostic, it is code. Measured against both kinds of input, the
/// discrimination is clean — `if (ready) doThing();` and `class Old {}` are code,
/// while `Note: this is fine`, `Use compute() instead.`, `The list is empty;` and
/// `coverage:ignore-line` are all prose. Nothing needs to be special-cased for the
/// pragma comments the parser rejects on its own.
///
/// Doc comments are never reported: `///` is documentation by definition, whatever it
/// contains.
///
/// **Consecutive commented-out lines are reported once**, on the first of the run,
/// and the fix removes the whole run. A ten-line block that was commented out is one
/// decision, not ten.
///
/// The fix deletes the lines, absorbing a following blank line the way the
/// package's other removal fixes do. It is safe because the lines do nothing — that
/// is the finding.
class AvoidCommentedOutCode extends AligRule {
  /// Warns when a comment holds code.
  AvoidCommentedOutCode(CustomLintConfigs configs) : super(_meta, configs);

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addCompilationUnit((unit) {
      for (final run in _commentedOutRunsIn(unit.beginToken, resolver)) {
        reporter.atOffset(
          offset: run.offset,
          length: run.length,
          diagnosticCode: code,
        );
      }
    });
  }

  @override
  List<Fix> getFixes() => [_RemoveCommentedCode()];
}

/// The runs of consecutive single-line comments whose contents are code.
List<SourceRange> _commentedOutRunsIn(Token first, CustomLintResolver resolver) {
  final runs = <SourceRange>[];
  final lineInfo = resolver.lineInfo;

  List<Token> current = [];
  void flush() {
    if (current.isEmpty) return;

    final text = current.map((token) => _contentOf(token.lexeme)).join('\n');
    if (_looksLikeCode(text)) {
      final start = current.first.offset;
      runs.add(SourceRange(start, current.last.end - start));
    }
    current = [];
  }

  for (final comment in _singleLineCommentsFrom(first)) {
    final previous = current.lastOrNull;
    final isConsecutive = previous != null &&
        lineInfo.getLocation(comment.offset).lineNumber ==
            lineInfo.getLocation(previous.offset).lineNumber + 1;
    if (!isConsecutive) flush();
    current.add(comment);
  }
  flush();

  return runs;
}

/// Every `//` comment in the file, in order, skipping documentation comments.
Iterable<Token> _singleLineCommentsFrom(Token first) sync* {
  for (Token? token = first; token != null; token = token.next) {
    for (Token? comment = token.precedingComments;
        comment != null;
        comment = comment.next) {
      if (comment.type != TokenType.SINGLE_LINE_COMMENT) continue;
      // `///` is documentation whatever it holds.
      if (comment.lexeme.startsWith('///')) continue;
      if (_isPragma(comment.lexeme)) continue;

      yield comment;
    }
    if (token.isEof) break;
  }
}

/// Whether [lexeme] is a comment addressed to tooling rather than to a reader.
///
/// These have to be skipped rather than merely not reported: a pragma sits directly
/// above the thing it annotates, so leaving it in would join the run below it and
/// stop that run from parsing as code — a false negative in exactly the place
/// somebody has already flagged.
bool _isPragma(String lexeme) {
  final content = _contentOf(lexeme).trim();

  return content.startsWith('ignore:') ||
      content.startsWith('ignore_for_file:') ||
      content.startsWith('expect_lint:') ||
      content.startsWith('coverage:') ||
      content.startsWith('dart format');
}

/// A comment's text without its leading slashes.
String _contentOf(String lexeme) => lexeme.replaceFirst(RegExp('^//+'), '');

/// Whether [text] parses as Dart, which is what separates code from prose.
bool _looksLikeCode(String text) {
  final trimmed = text.trim();
  // Empty content parses as an empty compilation unit, and a nested comment says
  // nothing about whether there is code inside it.
  if (trimmed.isEmpty || trimmed.startsWith('/')) return false;

  for (final candidate in [text, 'void _() { $text }']) {
    final result = parseString(content: candidate, throwIfDiagnostics: false);
    if (result.errors.isEmpty) return true;
  }

  return false;
}

class _RemoveCommentedCode extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    Diagnostic diagnostic,
    List<Diagnostic> others,
  ) {
    context.registry.addCompilationUnit((unit) {
      for (final run in _commentedOutRunsIn(unit.beginToken, resolver)) {
        if (run != diagnostic.sourceRange) continue;

        reporter
            .createChangeBuilder(
              message: 'Remove the commented-out code',
              priority: 60,
            )
            .addDartFileEdit((builder) {
          // The same line handling as the package's other removal fixes, so a
          // block that was separated by a blank line does not leave one behind.
          builder.addDeletion(
            lineRangeOfSpan(
              run.offset,
              run.end,
              resolver,
              absorbFollowingBlankLines: true,
            ),
          );
        });
      }
    });
  }
}
