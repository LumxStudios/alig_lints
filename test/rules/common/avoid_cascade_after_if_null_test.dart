import 'package:alig_lints/src/rules/common/avoid_cascade_after_if_null.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidCascadeAfterIfNull(CustomLintConfigs.empty);

  test('reports only the unparenthesised mix', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_cascade_after_if_null.dart',
      onLines: [12],
    );
  });

  test('fix parenthesises the grouping the code already has', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_cascade_after_if_null.dart',
      expectedPath:
          'test/fixtures/common/avoid_cascade_after_if_null.expected.dart',
    );
  });
}
