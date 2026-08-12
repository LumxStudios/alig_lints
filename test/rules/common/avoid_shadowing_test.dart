import 'package:alig_lints/src/rules/common/avoid_shadowing.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports inner declarations reusing an enclosing local name', () async {
    await expectRuleReports(
      AvoidShadowing(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_shadowing.dart',
      onLines: [4, 12, 18],
    );
  });
}
