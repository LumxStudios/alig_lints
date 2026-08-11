import 'package:alig_lints/src/rules/common/avoid_enum_values_by_index.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports values[...] but not reading index or iterating values',
      () async {
    await expectRuleReports(
      AvoidEnumValuesByIndex(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_enum_values_by_index.dart',
      onLines: [4, 8],
    );
  });
}
