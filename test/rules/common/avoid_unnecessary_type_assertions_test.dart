import 'package:alig_lints/src/rules/common/avoid_unnecessary_type_assertions.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports filters that keep every element, not ones that narrow',
      () async {
    await expectRuleReports(
      AvoidUnnecessaryTypeAssertions(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_unnecessary_type_assertions.dart',
      onLines: [7, 8, 9],
    );
  });
}
