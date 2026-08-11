import 'package:alig_lints/src/rules/common/avoid_constant_switches.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports constant subjects in statements and expressions', () async {
    await expectRuleReports(
      AvoidConstantSwitches(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_constant_switches.dart',
      onLines: [2, 10, 16],
    );
  });
}
