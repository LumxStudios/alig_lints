import 'package:alig_lints/src/rules/common/avoid_default_tostring.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports only targets with no toString anywhere in their hierarchy',
      () async {
    await expectRuleReports(
      AvoidDefaultTostring(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_default_tostring.dart',
      onLines: [41],
    );
  });
}
