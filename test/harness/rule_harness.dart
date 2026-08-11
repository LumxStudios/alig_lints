import 'dart:io';

import 'package:alig_lints/src/common/alig_rule.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Resolves [fixturePath] and returns the diagnostics [rule] reports for it.
Future<List<Diagnostic>> runRule(AligRule rule, String fixturePath) =>
    rule.testAnalyzeAndRun(File(_absolute(fixturePath)));

/// Applies every edit in [changes] to [source].
///
/// Edits are applied highest-offset-first so that earlier offsets remain valid.
String applyChanges(String source, List<PrioritizedSourceChange> changes) {
  final edits = <SourceEdit>[
    for (final change in changes)
      for (final fileEdit in change.change.edits) ...fileEdit.edits,
  ]..sort((a, b) => b.offset.compareTo(a.offset));

  var result = source;
  for (final edit in edits) {
    result = result.replaceRange(edit.offset, edit.end, edit.replacement);
  }

  return result;
}

/// Asserts that [rule] reports on exactly [onLines] (1-based) of [fixturePath].
Future<void> expectRuleReports(
  AligRule rule,
  String fixturePath, {
  required List<int> onLines,
}) async {
  final file = File(_absolute(fixturePath));
  final diagnostics = await rule.testAnalyzeAndRun(file);
  final lineStarts = _lineStarts(file.readAsStringSync());

  final reportedLines = [
    for (final diagnostic in diagnostics)
      _lineOf(lineStarts, diagnostic.offset),
  ]..sort();

  expect(reportedLines, onLines, reason: 'in $fixturePath');
}

/// Asserts that applying [rule]'s fix to [fixturePath] yields [expectedPath].
///
/// Every diagnostic the rule reports is fixed, so the expectation file shows
/// the fully cleaned-up source.
Future<void> expectFixProduces(
  AligRule rule,
  String fixturePath, {
  required String expectedPath,
}) async {
  final file = File(_absolute(fixturePath));
  final diagnostics = await rule.testAnalyzeAndRun(file);
  expect(
    diagnostics,
    isNotEmpty,
    reason: 'no diagnostic to fix in $fixturePath',
  );

  final fixes = rule.getFixes().whereType<DartFix>().toList();
  expect(fixes, hasLength(1), reason: '${rule.meta.name} must expose one fix');

  final changes = <PrioritizedSourceChange>[];
  for (final diagnostic in diagnostics) {
    changes.addAll(
      await fixes.single.testAnalyzeAndRun(file, diagnostic, diagnostics),
    );
  }
  expect(changes, isNotEmpty, reason: '${rule.meta.name} produced no edits');

  final actual = applyChanges(file.readAsStringSync(), changes);
  expect(actual, File(_absolute(expectedPath)).readAsStringSync());
}

String _absolute(String path) => p.normalize(p.absolute(path));

List<int> _lineStarts(String source) {
  final starts = <int>[0];
  for (var i = 0; i < source.length; i++) {
    if (source.codeUnitAt(i) == 0x0a) starts.add(i + 1);
  }

  return starts;
}

int _lineOf(List<int> lineStarts, int offset) {
  var line = 0;
  while (line + 1 < lineStarts.length && lineStarts[line + 1] <= offset) {
    line++;
  }

  return line + 1;
}
