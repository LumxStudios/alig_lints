import 'package:alig_lints/src/rules/common/prefer_simpler_patterns_null_check.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = PreferSimplerPatternsNullCheck(CustomLintConfigs.empty);

  test('reports patterns that only test for null', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/prefer_simpler_patterns_null_check.dart',
      onLines: [2, 6, 10],
    );
  });

  test('fix rewrites the case clause to a comparison', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/prefer_simpler_patterns_null_check.dart',
      expectedPath: 'test/fixtures/common/'
          'prefer_simpler_patterns_null_check.expected.dart',
    );
  });
}
