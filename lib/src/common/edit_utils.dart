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
