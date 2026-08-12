import 'package:alig_lints/src/rules/common/prefer_return_await.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = PreferReturnAwait(CustomLintConfigs.empty);

  test('reports returns inside try and finally guards only', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/prefer_return_await.dart',
      onLines: [5, 13],
    );
  });

  test('fix inserts await before the returned future', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/prefer_return_await.dart',
      expectedPath: 'test/fixtures/common/prefer_return_await.expected.dart',
    );
  });
}
