import 'package:alig_lints/src/rules/common/prefer_parentheses_with_if_null.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = PreferParenthesesWithIfNull(CustomLintConfigs.empty);

  test('reports unparenthesised binary right operands, not ?? chains', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/prefer_parentheses_with_if_null.dart',
      onLines: [4, 8],
    );
  });

  test('fix states the existing grouping', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/prefer_parentheses_with_if_null.dart',
      expectedPath:
          'test/fixtures/common/prefer_parentheses_with_if_null.expected.dart',
    );
  });
}
