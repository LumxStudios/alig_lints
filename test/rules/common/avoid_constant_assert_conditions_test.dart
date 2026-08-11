import 'package:alig_lints/src/rules/common/avoid_constant_assert_conditions.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidConstantAssertConditions(CustomLintConfigs.empty);

  test('reports constant conditions but exempts the assert(false) idiom',
      () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_constant_assert_conditions.dart',
      onLines: [3, 4, 5],
    );
  });

  test('fix removes always-true asserts only', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_constant_assert_conditions.dart',
      expectedPath:
          'test/fixtures/common/avoid_constant_assert_conditions.expected.dart',
    );
  });
}
