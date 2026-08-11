import 'package:alig_lints/src/rules/common/avoid_unnecessary_statements.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'package:test/test.dart';

import '../../harness/rule_harness.dart';

void main() {
  final rule = AvoidUnnecessaryStatements(CustomLintConfigs.empty);

  test('reports discarded values, not statements that do work', () async {
    await expectRuleReports(
      rule,
      'test/fixtures/common/avoid_unnecessary_statements.dart',
      onLines: [13, 14, 15, 16, 17],
    );
  });

  test('fix removes each dead statement line', () async {
    await expectFixProduces(
      rule,
      'test/fixtures/common/avoid_unnecessary_statements.dart',
      expectedPath:
          'test/fixtures/common/avoid_unnecessary_statements.expected.dart',
    );
  });
}
