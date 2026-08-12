import 'package:alig_lints/src/rules/common/avoid_never_passed_parameters.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports optionals no caller supplies, named or positional', () async {
    await expectRuleReports(
      AvoidNeverPassedParameters(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_never_passed_parameters.dart',
      onLines: [1, 17],
    );
  });
}
