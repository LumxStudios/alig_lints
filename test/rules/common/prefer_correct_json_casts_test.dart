import 'package:alig_lints/src/rules/common/prefer_correct_json_casts.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  test('reports narrow collection casts on decoded JSON only', () async {
    await expectRuleReports(
      PreferCorrectJsonCasts(CustomLintConfigs.empty),
      'test/fixtures/common/prefer_correct_json_casts.dart',
      onLines: [6, 7, 8],
    );
  });
}
