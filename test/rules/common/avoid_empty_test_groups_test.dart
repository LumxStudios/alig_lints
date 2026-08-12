import 'package:alig_lints/src/rules/common/avoid_empty_test_groups.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidEmptyTestGroups(CustomLintConfigs.empty);

  test('reports groups with no tests, including setup-only ones', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_empty_test_groups.dart',
      onLines: [4, 6],
    );
  });

  test('fix removes the group and its blank line', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_empty_test_groups.dart',
      expectedPath:
          'test/fixtures/common/avoid_empty_test_groups.expected.dart',
    );
  });
}
