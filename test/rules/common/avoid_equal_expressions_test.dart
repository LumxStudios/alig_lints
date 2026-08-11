import 'package:alig_lints/src/rules/common/avoid_equal_expressions.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidEqualExpressions(CustomLintConfigs.empty);

  test('reports collapsible and constant operators, not + or comparisons',
      () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_equal_expressions.dart',
      onLines: [9, 10, 11, 12, 13],
    );
  });

  test('fix collapses only the operators where one side is the whole value',
      () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_equal_expressions.dart',
      expectedPath: 'test/fixtures/common/avoid_equal_expressions.expected.dart',
    );
  });
}
