import 'package:alig_lints/src/rules/common/prefer_simpler_boolean_expressions.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports one-literal conditionals, not two-literal or literal-free ones',
      () async {
    await expectRuleReports(
      PreferSimplerBooleanExpressions(CustomLintConfigs.empty),
      'test/fixtures/common/prefer_simpler_boolean_expressions.dart',
      onLines: [7, 8, 9, 10, 11],
    );
  });
}
