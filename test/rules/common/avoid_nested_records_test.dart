import 'package:alig_lints/src/rules/common/avoid_nested_records.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports the offending shape only', () async {
    await expectRuleReports(
      AvoidNestedRecords(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_nested_records.dart',
      onLines: [1, 3],
    );
  });
}
