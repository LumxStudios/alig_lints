import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// The range covering every line [node] occupies, including its trailing
/// newline and its leading indentation.
///
/// Deleting `node.sourceRange` for a statement leaves an empty,
/// whitespace-only line behind; deleting this range removes the line entirely.
SourceRange lineRangeOf(AstNode node, CustomLintResolver resolver) {
  final lineInfo = resolver.lineInfo;
  final contentLength = resolver.source.contents.data.length;

  final startLine = lineInfo.getLocation(node.offset).lineNumber;
  final endLine = lineInfo.getLocation(node.end).lineNumber;

  final start = lineInfo.getOffsetOfLine(startLine - 1);
  final end = endLine < lineInfo.lineCount
      ? lineInfo.getOffsetOfLine(endLine)
      : contentLength;

  return SourceRange(start, end - start);
}

/// The range that removes [node] along with the separator and whitespace
/// between it and whatever precedes it, which ends at [previousEnd].
///
/// Use this instead of [lineRangeOf] when [node] is one element of a list —
/// a cascade section, argument, or collection element — because the line it sits
/// on may also carry punctuation belonging to the enclosing construct, such as
/// the `;` terminating a cascade.
SourceRange rangeFollowing(int previousEnd, AstNode node) =>
    SourceRange(previousEnd, node.end - previousEnd);

/// The range that removes [node] from a comma-separated list, leaving the list's
/// punctuation valid.
///
/// - When a comma follows [node], that comma goes with it. If [node] was then
///   the only thing on its line, the line goes too, so no blank line is left
///   behind.
/// - When no comma follows — [node] is the last item and the list has no
///   trailing comma — the *preceding* comma is removed instead. Absorbing the
///   following text would delete the list's closing punctuation.
SourceRange rangeRemovingListItem(AstNode node, CustomLintResolver resolver) {
  final source = resolver.source.contents.data;

  var afterSpaces = node.end;
  while (afterSpaces < source.length && _isBlank(source[afterSpaces])) {
    afterSpaces++;
  }
  final hasFollowingComma =
      afterSpaces < source.length && source[afterSpaces] == ',';

  if (!hasFollowingComma) {
    var start = node.offset;
    while (start > 0 && _isBlank(source[start - 1])) {
      start--;
    }
    if (start > 0 && source[start - 1] == ',') start--;

    return SourceRange(start, node.end - start);
  }

  var end = afterSpaces + 1;
  while (end < source.length &&
      (source[end] == ' ' || source[end] == '\t')) {
    end++;
  }

  var lineStart = node.offset;
  while (lineStart > 0 && source.codeUnitAt(lineStart - 1) != 0x0a) {
    lineStart--;
  }

  final nothingBefore = source.substring(lineStart, node.offset).trim().isEmpty;
  final nothingAfter = end >= source.length || source[end] == '\n';

  if (nothingBefore && nothingAfter) {
    final withNewline = end < source.length ? end + 1 : end;

    return SourceRange(lineStart, withNewline - lineStart);
  }

  return SourceRange(node.offset, end - node.offset);
}

/// The range covering [node] together with the whitespace immediately before it.
///
/// Use this to delete an optional clause — a `with`, `implements` or `on` clause
/// — without leaving a double space behind.
SourceRange rangeWithLeadingSpace(AstNode node, CustomLintResolver resolver) {
  final source = resolver.source.contents.data;

  var start = node.offset;
  while (start > 0 && _isBlank(source[start - 1])) {
    start--;
  }

  return SourceRange(start, node.end - start);
}

bool _isBlank(String character) =>
    character == ' ' || character == '\t' || character == '\n';
