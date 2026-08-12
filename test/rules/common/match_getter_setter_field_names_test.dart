import 'package:alig_lints/src/rules/common/match_getter_setter_field_names.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports single-field accessors whose names disagree', () async {
    await expectRuleReports(
      MatchGetterSetterFieldNames(CustomLintConfigs.empty),
      'test/fixtures/common/match_getter_setter_field_names.dart',
      onLines: [7, 11],
    );
  });
}
