import 'package:alig_lints/src/rules/common/avoid_map_keys_contains.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidMapKeysContains(CustomLintConfigs.empty);

  test('reports keys.contains, not values.contains or plain iterables',
      () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_map_keys_contains.dart',
      onLines: [6, 10],
    );
  });

  test('fix swaps in containsKey and keeps the argument', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_map_keys_contains.dart',
      expectedPath: 'test/fixtures/common/avoid_map_keys_contains.expected.dart',
    );
  });
}
