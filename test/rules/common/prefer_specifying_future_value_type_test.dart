import 'package:alig_lints/src/rules/common/prefer_specifying_future_value_type.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports nullable arguments to non-nullable futures only', () async {
    await expectRuleReports(
      PreferSpecifyingFutureValueType(CustomLintConfigs.empty),
      'test/fixtures/common/prefer_specifying_future_value_type.dart',
      onLines: [10, 12],
    );
  });
}
