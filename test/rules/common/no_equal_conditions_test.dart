import 'package:alig_lints/src/rules/common/no_equal_conditions.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports the dead branch, not distinct conditions or repeated calls',
      () async {
    await expectRuleReports(
      NoEqualConditions(CustomLintConfigs.empty),
      'test/fixtures/common/no_equal_conditions.dart',
      onLines: [11],
    );
  });
}
