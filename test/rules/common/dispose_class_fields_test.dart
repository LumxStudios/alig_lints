import 'package:alig_lints/src/rules/common/dispose_class_fields.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports fields a present teardown method misses', () async {
    await expectRuleReports(
      DisposeClassFields(CustomLintConfigs.empty),
      'test/fixtures/common/dispose_class_fields.dart',
      onLines: [6],
    );
  });
}
