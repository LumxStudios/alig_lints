import 'package:alig_lints/src/rules/common/prefer_null_aware_spread.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports null guards around a spread of the tested value', () async {
    await expectRuleReports(
      PreferNullAwareSpread(CustomLintConfigs.empty),
      'test/fixtures/common/prefer_null_aware_spread.dart',
      onLines: [2, 6, 10, 14],
    );
  });
}
