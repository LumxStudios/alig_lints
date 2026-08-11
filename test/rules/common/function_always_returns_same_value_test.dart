import 'package:alig_lints/src/rules/common/function_always_returns_same_value.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports branching functions with one constant, not single returns',
      () async {
    await expectRuleReports(
      FunctionAlwaysReturnsSameValue(CustomLintConfigs.empty),
      'test/fixtures/common/function_always_returns_same_value.dart',
      onLines: [1, 12, 21],
    );
  });
}
