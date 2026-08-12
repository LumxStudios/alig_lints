import 'package:alig_lints/src/rules/common/avoid_referencing_discarded_variables.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports the offending shape only', () async {
    await expectRuleReports(
      AvoidReferencingDiscardedVariables(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_referencing_discarded_variables.dart',
      onLines: [3, 7, 12],
    );
  });
}
