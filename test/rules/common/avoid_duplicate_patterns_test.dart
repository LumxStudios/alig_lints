import 'package:alig_lints/src/rules/common/avoid_duplicate_patterns.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidDuplicatePatterns(CustomLintConfigs.empty);

  test('reports duplicates anywhere in a flattened chain', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_duplicate_patterns.dart',
      onLines: [3, 5, 7],
    );
  });

  test('fix rewrites the chain from its deduplicated operands', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_duplicate_patterns.dart',
      expectedPath: 'test/fixtures/common/avoid_duplicate_patterns.expected.dart',
    );
  });
}
