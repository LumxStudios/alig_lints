import 'package:alig_lints/src/rules/common/avoid_self_compare.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports self comparisons but leaves the double NaN idiom alone',
      () async {
    await expectRuleReports(
      AvoidSelfCompare(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_self_compare.dart',
      onLines: [8, 9, 10, 11, 12],
    );
  });
}
