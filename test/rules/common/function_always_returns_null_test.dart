import 'package:alig_lints/src/rules/common/function_always_returns_null.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports nullable functions that only return null, skipping overrides',
      () async {
    await expectRuleReports(
      FunctionAlwaysReturnsNull(CustomLintConfigs.empty),
      'test/fixtures/common/function_always_returns_null.dart',
      onLines: [1, 5, 7, 15, 20],
    );
  });
}
