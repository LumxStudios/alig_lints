import 'package:alig_lints/src/rules/common/no_equal_switch_expression_cases.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports repeated result values, including against the wildcard',
      () async {
    await expectRuleReports(
      NoEqualSwitchExpressionCases(CustomLintConfigs.empty),
      'test/fixtures/common/no_equal_switch_expression_cases.dart',
      onLines: [4, 11, 23],
    );
  });
}
