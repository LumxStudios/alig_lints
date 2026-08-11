import 'package:alig_lints/src/rules/common/no_equal_nested_conditions.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports nested repeats in then and else, skipping reassigned variables '
      'and else-if chains', () async {
    await expectRuleReports(
      NoEqualNestedConditions(CustomLintConfigs.empty),
      'test/fixtures/common/no_equal_nested_conditions.dart',
      onLines: [8, 16],
    );
  });
}
