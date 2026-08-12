import 'package:alig_lints/src/rules/common/prefer_overriding_parent_equality.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports subclasses that add fields and inherit equality', () async {
    await expectRuleReports(
      PreferOverridingParentEquality(CustomLintConfigs.empty),
      'test/fixtures/common/prefer_overriding_parent_equality.dart',
      onLines: [13],
    );
  });
}
