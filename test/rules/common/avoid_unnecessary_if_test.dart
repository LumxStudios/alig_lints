import 'package:alig_lints/src/rules/common/avoid_unnecessary_if.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidUnnecessaryIf(CustomLintConfigs.empty);

  test('reports ifs whose return matches the one after them', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_unnecessary_if.dart',
      onLines: [4, 12, 20],
    );
  });

  test('fix removes the if only where the condition is side-effect-free',
      () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_unnecessary_if.dart',
      expectedPath: 'test/fixtures/common/avoid_unnecessary_if.expected.dart',
    );
  });
}
