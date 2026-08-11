import 'package:alig_lints/src/rules/common/avoid_multi_assignment.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports chained assignments once each, not single ones', () async {
    await expectRuleReports(
      AvoidMultiAssignment(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_multi_assignment.dart',
      onLines: [12, 13, 14],
    );
  });
}
