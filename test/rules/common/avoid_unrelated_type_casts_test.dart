import 'package:alig_lints/src/rules/common/avoid_unrelated_type_casts.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports casts to a closed type, not between open classes', () async {
    await expectRuleReports(
      AvoidUnrelatedTypeCasts(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_unrelated_type_casts.dart',
      onLines: [13, 14, 15],
    );
  });
}
