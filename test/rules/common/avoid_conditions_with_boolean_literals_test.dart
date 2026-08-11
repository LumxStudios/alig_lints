import 'package:alig_lints/src/rules/common/avoid_conditions_with_boolean_literals.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidConditionsWithBooleanLiterals(CustomLintConfigs.empty);

  test('reports every logical condition holding a boolean literal', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_conditions_with_boolean_literals.dart',
      onLines: [6, 7, 8, 9, 10, 11, 12, 13, 14],
    );
  });

  test('fix collapses only where no evaluated operand would be dropped',
      () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_conditions_with_boolean_literals.dart',
      expectedPath: 'test/fixtures/common/'
          'avoid_conditions_with_boolean_literals.expected.dart',
    );
  });
}
