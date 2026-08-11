import 'package:alig_lints/src/rules/common/prefer_null_aware_elements.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports null guards whose element is the tested value', () async {
    await expectRuleReports(
      PreferNullAwareElements(CustomLintConfigs.empty),
      'test/fixtures/common/prefer_null_aware_elements.dart',
      onLines: [2, 6, 10, 14],
    );
  });
}
