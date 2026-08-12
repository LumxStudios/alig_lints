import 'package:alig_lints/src/rules/common/avoid_missing_completer_stack_trace.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports single-argument completeError only', () async {
    await expectRuleReports(
      AvoidMissingCompleterStackTrace(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_missing_completer_stack_trace.dart',
      onLines: [4, 11],
    );
  });
}
