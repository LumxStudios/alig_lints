import 'package:alig_lints/src/rules/common/avoid_duplicate_mixins.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidDuplicateMixins(CustomLintConfigs.empty);

  test('reports mixins already applied up the chain and within one clause',
      () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_duplicate_mixins.dart',
      onLines: [9, 13, 15],
    );
  });

  test('fix drops the clause when the duplicate is its only mixin', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_duplicate_mixins.dart',
      expectedPath: 'test/fixtures/common/avoid_duplicate_mixins.expected.dart',
    );
  });
}
