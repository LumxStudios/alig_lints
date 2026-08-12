import 'package:alig_lints/src/rules/common/avoid_passing_async_when_sync_expected.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports async closures for void parameters only', () async {
    await expectRuleReports(
      AvoidPassingAsyncWhenSyncExpected(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_passing_async_when_sync_expected.dart',
      onLines: [10, 18, 22],
    );
  });
}
