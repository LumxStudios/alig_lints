import 'package:alig_lints/src/rules/common/avoid_suspicious_global_reference.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports globals that shadow an inherited or extended member', () async {
    await expectRuleReports(
      AvoidSuspiciousGlobalReference(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_suspicious_global_reference.dart',
      onLines: [10, 26],
    );
  });
}
