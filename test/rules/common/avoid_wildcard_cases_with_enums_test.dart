import 'package:alig_lints/src/rules/common/avoid_wildcard_cases_with_enums.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports wildcards and defaults on enum switches only', () async {
    await expectRuleReports(
      AvoidWildcardCasesWithEnums(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_wildcard_cases_with_enums.dart',
      onLines: [7, 16, 23, 29],
    );
  });
}
