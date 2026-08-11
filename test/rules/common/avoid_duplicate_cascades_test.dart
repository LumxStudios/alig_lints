import 'package:alig_lints/src/rules/common/avoid_duplicate_cascades.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidDuplicateCascades(CustomLintConfigs.empty);

  test('reports only the repeated cascade sections', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_duplicate_cascades.dart',
      onLines: [11, 16],
    );
  });

  test('fix removes the duplicate, keeping the cascade terminator', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_duplicate_cascades.dart',
      expectedPath:
          'test/fixtures/common/avoid_duplicate_cascades.expected.dart',
    );
  });

  test('ignored-methods suppresses accumulator repetition by default', () {
    expect(rule.ignoredMethods, contains('add'));
  });
}
