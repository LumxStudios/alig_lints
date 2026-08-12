import 'package:alig_lints/src/rules/common/move_variable_closer_to_its_usage.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports variables whose every use is in one inner block', () async {
    await expectRuleReports(
      MoveVariableCloserToItsUsage(CustomLintConfigs.empty),
      'test/fixtures/common/move_variable_closer_to_its_usage.dart',
      onLines: [2],
    );
  });
}
