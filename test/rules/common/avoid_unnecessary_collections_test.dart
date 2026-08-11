import 'package:alig_lints/src/rules/common/avoid_unnecessary_collections.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidUnnecessaryCollections(CustomLintConfigs.empty);

  test('reports one-element literals reduced to their element', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_unnecessary_collections.dart',
      onLines: [4, 5, 6, 7, 11],
    );
  });

  test('fix replaces the whole expression with the element', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_unnecessary_collections.dart',
      expectedPath:
          'test/fixtures/common/avoid_unnecessary_collections.expected.dart',
    );
  });
}
