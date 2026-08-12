import 'package:alig_lints/src/rules/common/prefer_unique_test_names.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports repeats within a group, not across groups', () async {
    await expectRuleReports(
      PreferUniqueTestNames(CustomLintConfigs.empty),
      'test/fixtures/common/prefer_unique_test_names.dart',
      onLines: [8, 17],
    );
  });
}
