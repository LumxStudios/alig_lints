import 'package:alig_lints/src/rules/common/prefer_iterable_of.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = PreferIterableOf(CustomLintConfigs.empty);

  test('reports every core-collection from(), including the dynamic source',
      () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/prefer_iterable_of.dart',
      onLines: [2, 3, 9, 15, 21],
    );
  });

  test('fix leaves the dynamic source alone, where of() would not compile',
      () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/prefer_iterable_of.dart',
      expectedPath: 'test/fixtures/common/prefer_iterable_of.expected.dart',
    );
  });
}
