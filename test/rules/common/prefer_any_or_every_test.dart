import 'package:alig_lints/src/rules/common/prefer_any_or_every.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = PreferAnyOrEvery(CustomLintConfigs.empty);

  test('reports where-then-emptiness chains only', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/prefer_any_or_every.dart',
      onLines: [4, 5, 6, 10],
    );
  });

  test('fix negates for the isEmpty form', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/prefer_any_or_every.dart',
      expectedPath: 'test/fixtures/common/prefer_any_or_every.expected.dart',
    );
  });
}
