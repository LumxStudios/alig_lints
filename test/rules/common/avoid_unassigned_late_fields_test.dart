import 'package:alig_lints/src/rules/common/avoid_unassigned_late_fields.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports private late fields nothing in the class assigns', () async {
    await expectRuleReports(
      AvoidUnassignedLateFields(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_unassigned_late_fields.dart',
      onLines: [2],
    );
  });
}
