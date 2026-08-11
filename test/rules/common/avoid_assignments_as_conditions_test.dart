import 'package:alig_lints/src/rules/common/avoid_assignments_as_conditions.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports assignments in every condition position, not in for updates',
      () async {
    await expectRuleReports(
      AvoidAssignmentsAsConditions(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_assignments_as_conditions.dart',
      onLines: [7, 8, 9, 10, 13, 14],
    );
  });
}
