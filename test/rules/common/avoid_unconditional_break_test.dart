import 'package:alig_lints/src/rules/common/avoid_unconditional_break.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports unconditional exits, not guarded ones or switch breaks',
      () async {
    await expectRuleReports(
      AvoidUnconditionalBreak(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_unconditional_break.dart',
      onLines: [4, 12, 22],
    );
  });
}
