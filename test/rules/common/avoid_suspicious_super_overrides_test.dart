import 'package:alig_lints/src/rules/common/avoid_suspicious_super_overrides.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports getters hiding a field the super constructor is given', () async {
    await expectRuleReports(
      AvoidSuspiciousSuperOverrides(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_suspicious_super_overrides.dart',
      onLines: [11, 18],
    );
  });
}
