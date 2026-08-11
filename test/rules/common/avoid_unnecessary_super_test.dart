import 'package:alig_lints/src/rules/common/avoid_unnecessary_super.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidUnnecessarySuper(CustomLintConfigs.empty);

  test('reports bare super() calls and prefixes that resolve the same way',
      () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_unnecessary_super.dart',
      onLines: [10, 16, 25],
    );
  });

  test('fix drops the colon with the only initializer and keeps the rest',
      () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_unnecessary_super.dart',
      expectedPath: 'test/fixtures/common/avoid_unnecessary_super.expected.dart',
    );
  });
}
