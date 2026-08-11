import 'package:alig_lints/src/rules/common/no_equal_switch_case.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports duplicate bodies, skipping fall-through and break-only cases',
      () async {
    await expectRuleReports(
      NoEqualSwitchCase(CustomLintConfigs.empty),
      'test/fixtures/common/no_equal_switch_case.dart',
      onLines: [7, 22, 38],
    );
  });
}
