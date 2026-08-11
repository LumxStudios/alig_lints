import 'package:alig_lints/src/rules/common/avoid_constant_conditions.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports constant comparisons, leaving the neighbouring rules their own '
      'shapes', () async {
    await expectRuleReports(
      AvoidConstantConditions(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_constant_conditions.dart',
      onLines: [4, 5, 6, 7],
    );
  });
}
