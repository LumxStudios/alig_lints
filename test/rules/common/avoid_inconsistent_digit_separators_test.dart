import 'package:alig_lints/src/rules/common/avoid_inconsistent_digit_separators.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports the offending shape only', () async {
    await expectRuleReports(
      AvoidInconsistentDigitSeparators(CustomLintConfigs.empty),
      'test/fixtures/common/avoid_inconsistent_digit_separators.dart',
      onLines: [1, 2, 3],
    );
  });
}
