import 'package:alig_lints/src/rules/common/avoid_misused_set_literals.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports discarded set literals in functions, methods and closures',
      () async {
    await expectRuleReports(
      AvoidMisusedSetLiterals(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_misused_set_literals.dart',
      onLines: [5, 10, 13, 29],
    );
  });
}
