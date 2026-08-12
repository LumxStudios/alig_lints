import 'package:alig_lints/src/rules/common/match_base_class_default_value.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports defaults that differ from the overridden ones', () async {
    await expectRuleReports(
      MatchBaseClassDefaultValue(CustomLintConfigs.empty),
      'test/fixtures/common/match_base_class_default_value.dart',
      onLines: [12, 17],
    );
  });
}
