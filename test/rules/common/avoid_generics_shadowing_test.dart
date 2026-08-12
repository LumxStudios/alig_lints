import 'package:alig_lints/src/rules/common/avoid_generics_shadowing.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports the offending shape only', () async {
    await expectRuleReports(
      AvoidGenericsShadowing(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_generics_shadowing.dart',
      onLines: [9, 15, 17],
    );
  });
}
