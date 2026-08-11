import 'package:alig_lints/src/rules/common/avoid_duplicate_switch_case_conditions.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports the shadowed repeat in statements and expressions, but not a '
      'differently guarded case', () async {
    await expectRuleReports(
      AvoidDuplicateSwitchCaseConditions(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_duplicate_switch_case_conditions.dart',
      onLines: [7, 21],
    );
  });
}
