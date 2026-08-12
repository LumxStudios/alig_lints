import 'package:alig_lints/src/rules/common/avoid_nested_futures.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports futures containing futures, not lists of futures', () async {
    await expectRuleReports(
      AvoidNestedFutures(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_nested_futures.dart',
      onLines: [3, 6, 8, 11],
    );
  });
}
