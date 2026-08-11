import 'package:alig_lints/src/rules/common/avoid_empty_spread.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidEmptySpread(CustomLintConfigs.empty);

  test('reports empty list, set and map spreads', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_empty_spread.dart',
      onLines: [6, 11, 14],
    );
  });

  test('fix removes the spread on its own line and inline', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_empty_spread.dart',
      expectedPath: 'test/fixtures/common/avoid_empty_spread.expected.dart',
    );
  });
}
