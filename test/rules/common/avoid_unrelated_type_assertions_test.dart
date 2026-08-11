import 'package:alig_lints/src/rules/common/avoid_unrelated_type_assertions.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports checks against a closed type, not between open classes',
      () async {
    await expectRuleReports(
      AvoidUnrelatedTypeAssertions(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_unrelated_type_assertions.dart',
      onLines: [8, 9, 10, 22],
    );
  });
}
