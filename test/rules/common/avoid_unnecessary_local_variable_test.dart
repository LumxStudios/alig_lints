import 'package:alig_lints/src/rules/common/avoid_unnecessary_local_variable.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports only variables whose single use is another local initializer',
      () async {
    await expectRuleReports(
      AvoidUnnecessaryLocalVariable(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_unnecessary_local_variable.dart',
      onLines: [4, 31, 32],
    );
  });
}
