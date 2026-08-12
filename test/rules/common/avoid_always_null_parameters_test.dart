import 'package:alig_lints/src/rules/common/avoid_always_null_parameters.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports parameters that are null at every call', () async {
    await expectRuleReports(
      AvoidAlwaysNullParameters(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_always_null_parameters.dart',
      onLines: [1],
    );
  });
}
