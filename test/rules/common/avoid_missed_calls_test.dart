import 'package:alig_lints/src/rules/common/avoid_missed_calls.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidMissedCalls(CustomLintConfigs.empty);

  test('reports tear-offs where a value is wanted, not where a callback is',
      () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_missed_calls.dart',
      onLines: [16, 17, 18, 28],
    );
  });

  test('fix adds () only where the method needs no arguments', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_missed_calls.dart',
      expectedPath: 'test/fixtures/common/avoid_missed_calls.expected.dart',
    );
  });
}
