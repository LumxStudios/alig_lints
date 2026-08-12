import 'package:alig_lints/src/rules/common/avoid_misused_test_matchers.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports matchers that cannot fit the value type', () async {
    await expectRuleReports(
      AvoidMisusedTestMatchers(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_misused_test_matchers.dart',
      onLines: [16, 17, 18, 19],
    );
  });
}
