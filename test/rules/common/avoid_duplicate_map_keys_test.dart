import 'package:alig_lints/src/rules/common/avoid_duplicate_map_keys.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidDuplicateMapKeys(CustomLintConfigs.empty);

  test('reports the later entry, which is the one that wins', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_duplicate_map_keys.dart',
      onLines: [5, 8],
    );
  });

  test('fix deletes the discarded entry on its own line and inline', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_duplicate_map_keys.dart',
      expectedPath: 'test/fixtures/common/avoid_duplicate_map_keys.expected.dart',
    );
  });
}
