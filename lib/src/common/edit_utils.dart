import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

/// The range covering every line [node] occupies, including its trailing
/// newline and its leading indentation.
///
/// Deleting `node.sourceRange` for a statement leaves an empty,
/// whitespace-only line behind; deleting this range removes the line entirely.
/// Set [absorbFollowingBlankLines] when removing a statement that a blank line
/// separated from what follows. That blank line existed to space the statement
/// from its neighbour; left behind, it becomes stray leading whitespace at the
/// top of the block.
SourceRange lineRangeOf(
  AstNode node,
  CustomLintResolver resolver, {
  bool absorbFollowingBlankLines = false,
}) =>
    lineRangeOfSpan(
      node.offset,
      node.end,
      resolver,
      absorbFollowingBlankLines: absorbFollowingBlankLines,
    );

/// [lineRangeOf] for a span that no single [AstNode] covers.
///
/// A declaration's own range begins after its metadata, so deleting it together
/// with its annotations means starting from the first annotation's offset.
SourceRange lineRangeOfSpan(
  int offset,
  int endOffset,
  CustomLintResolver resolver, {
  bool absorbFollowingBlankLines = false,
}) {
  final lineInfo = resolver.lineInfo;
  final source = resolver.source.contents.data;

  final startLine = lineInfo.getLocation(offset).lineNumber;
  final endLine = lineInfo.getLocation(endOffset).lineNumber;

  final start = lineInfo.getOffsetOfLine(startLine - 1);
  var line = endLine;
  var end =
      line < lineInfo.lineCount ? lineInfo.getOffsetOfLine(line) : source.length;

  if (absorbFollowingBlankLines) {
    while (line < lineInfo.lineCount) {
      final nextEnd = line + 1 < lineInfo.lineCount
          ? lineInfo.getOffsetOfLine(line + 1)
          : source.length;
      if (source.substring(end, nextEnd).trim().isNotEmpty) break;

      end = nextEnd;
      line++;
    }
  }

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
SourceRange rangeWithLeadingSpace(AstNode node, CustomLintResolver resolver) =>
    rangeWithLeadingSpaceBetween(node.offset, node.end, resolver);

/// The range from [offset] to [end] extended backwards over any whitespace.
///
/// The offset form exists for clauses introduced by a bare token, such as a type
/// parameter's `extends`, where there is no single [AstNode] spanning the part to
/// remove.
SourceRange rangeWithLeadingSpaceBetween(
  int offset,
  int end,
  CustomLintResolver resolver,
) {
  final source = resolver.source.contents.data;

  var start = offset;
  while (start > 0 && _isBlank(source[start - 1])) {
    start--;
  }

  return SourceRange(start, end - start);
}

/// The whitespace at the start of the line [node] begins on.
String indentationOf(AstNode node, CustomLintResolver resolver) {
  final source = resolver.source.contents.data;

  var lineStart = node.offset;
  while (lineStart > 0 && source.codeUnitAt(lineStart - 1) != 0x0a) {
    lineStart--;
  }

  final line = source.substring(lineStart, node.offset);
  final indent = line.length - line.trimLeft().length;

  return line.substring(0, indent);
}

/// The source of [block]'s statements, re-indented to start at [targetIndent].
///
/// Use this when a fix unwraps a block into the position its enclosing statement
/// occupied — removing an `else`, collapsing an `if`, inlining a body. Emitting
/// `block.toSource()` instead would leave every line at its old depth and the
/// braces behind.
///
/// Lines after the first are shifted left by however much deeper the block's
/// contents sit than [targetIndent], so relative indentation inside the block is
/// preserved. Blank lines are left blank rather than being given trailing spaces.
String reindentedBody(
  Block block,
  String targetIndent,
  CustomLintResolver resolver,
) {
  final statements = block.statements;
  if (statements.isEmpty) return '';

  final source = resolver.source.contents.data;
  final body = source.substring(statements.first.offset, statements.last.end);

  final currentIndent = indentationOf(statements.first, resolver).length;
  final shift = currentIndent - targetIndent.length;
  if (shift <= 0) return body;

  final lines = body.split('\n');

  // The first line starts at the statement itself, so it carries no indentation
  // of its own — the caller places it. Every later line already holds its
  // absolute indentation, so shifting it left by [shift] lands it exactly at
  // [targetIndent].
  return [
    lines.first,
    for (final line in lines.skip(1))
      if (line.trim().isEmpty) '' else _shiftLeft(line, shift),
  ].join('\n');
}

/// [line] with up to [amount] leading spaces removed.
String _shiftLeft(String line, int amount) {
  var removed = 0;
  var index = 0;
  while (index < line.length && removed < amount && line[index] == ' ') {
    index++;
    removed++;
  }

  return line.substring(index);
}

bool _isBlank(String character) =>
    character == ' ' || character == '\t' || character == '\n';
